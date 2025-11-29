/// <reference path="../pb_data/types.d.ts" />
import { RecordService } from 'pocketbase';

const NOTIFICATIONS = 'notifications';
const COLLECTIONS = {
  bookings: 'court_bookings',
  posts: 'posts',
  postComments: 'post_comments',
  postLikes: 'post_likes',
  recruitmentPosts: 'recruitment_posts',
  recruitmentApplicants: 'recruitment_applicants',
  friendRequests: 'friend_requests',
};

async function createNotification(dao, body) {
  try {
    const notifications = new RecordService(NOTIFICATIONS, dao);
    await notifications.create(body);
  } catch (err) {
    console.error('Failed to create notification', { body, err });
  }
}

async function safeGetOne(service, id) {
  try {
    return await service.getOne(id);
  } catch (err) {
    console.error('Failed to fetch related record', { collection: service.collectionId, id, err });
    return null;
  }
}

function statusChangedTo(event, statusValue) {
  const current = event.record?.get?.('status');
  const previous = event.oldRecord?.get?.('status');
  return current === statusValue && previous !== statusValue;
}

onRecordAfterCreate(COLLECTIONS.bookings, async (event) => {
  const status = event.record.get('status');
  if (status === 'confirmed') {
    await createNotification(event.dao, {
      user: event.record.get('user_id'),
      type: 'booking_success',
      title: 'Đặt sân thành công',
      body: 'Lịch đặt sân của bạn đã được xác nhận.',
      target_type: 'booking',
      payload: { bookingId: event.record.id },
    });
  } else if (status === 'cancelled') {
    await createNotification(event.dao, {
      user: event.record.get('user_id'),
      type: 'booking_cancelled',
      title: 'Đặt sân bị hủy',
      body: event.record.get('cancel_reason') ?? 'Lịch đặt sân của bạn đã bị hủy.',
      target_type: 'booking',
      payload: { bookingId: event.record.id },
    });
  }
});

onRecordAfterUpdate(COLLECTIONS.bookings, async (event) => {
  if (statusChangedTo(event, 'confirmed')) {
    await createNotification(event.dao, {
      user: event.record.get('user_id'),
      type: 'booking_success',
      title: 'Đặt sân thành công',
      body: 'Lịch đặt sân của bạn đã được xác nhận.',
      target_type: 'booking',
      payload: { bookingId: event.record.id },
    });
  }

  if (statusChangedTo(event, 'cancelled')) {
    await createNotification(event.dao, {
      user: event.record.get('user_id'),
      type: 'booking_cancelled',
      title: 'Đặt sân bị hủy',
      body: event.record.get('cancel_reason') ?? 'Lịch đặt sân của bạn đã bị hủy.',
      target_type: 'booking',
      payload: { bookingId: event.record.id },
    });
  }
});

onRecordAfterCreate(COLLECTIONS.postComments, async (event) => {
  const postId = event.record.get('post');
  if (!postId) return;

  const postsService = new RecordService(COLLECTIONS.posts, event.dao);
  const post = await safeGetOne(postsService, postId);
  const ownerId = post?.get?.('author');
  if (!ownerId || ownerId === event.record.get('author')) return;

  await createNotification(event.dao, {
    user: ownerId,
    sender: event.record.get('author'),
    type: 'post_commented',
    title: 'Có bình luận mới',
    body: 'Ai đó đã bình luận vào bài viết của bạn.',
    target_type: 'post',
    payload: { postId, commentId: event.record.id },
  });
});

onRecordAfterCreate(COLLECTIONS.postLikes, async (event) => {
  const postId = event.record.get('post');
  if (!postId) return;

  const postsService = new RecordService(COLLECTIONS.posts, event.dao);
  const post = await safeGetOne(postsService, postId);
  const ownerId = post?.get?.('author');
  if (!ownerId || ownerId === event.record.get('user')) return;

  await createNotification(event.dao, {
    user: ownerId,
    sender: event.record.get('user'),
    type: 'post_liked',
    title: 'Bài viết được thích',
    body: 'Bài viết của bạn vừa nhận được lượt thích.',
    target_type: 'post',
    payload: { postId },
  });
});

onRecordAfterCreate(COLLECTIONS.recruitmentApplicants, async (event) => {
  const recruitmentId = event.record.get('recruitment');
  if (!recruitmentId) return;

  const recruitmentService = new RecordService(
    COLLECTIONS.recruitmentPosts,
    event.dao,
  );
  const recruitment = await safeGetOne(recruitmentService, recruitmentId);
  const ownerId = recruitment?.get?.('author');
  if (!ownerId) return;

  await createNotification(event.dao, {
    user: ownerId,
    sender: event.record.get('user'),
    type: 'recruitment_applied',
    title: 'Có yêu cầu tham gia mới',
    body: 'Một người chơi muốn tham gia đội của bạn.',
    target_type: 'recruitment_post',
    payload: { recruitmentPostId: recruitmentId, applicationId: event.record.id },
  });
});

onRecordAfterUpdate(COLLECTIONS.recruitmentApplicants, async (event) => {
  const status = event.record.get('status');
  if (!['accepted', 'rejected'].includes(status) || statusChangedTo(event, status) === false) {
    return;
  }

  const recruitmentId = event.record.get('recruitment');
  const recruitmentService = new RecordService(
    COLLECTIONS.recruitmentPosts,
    event.dao,
  );
  const recruitment = recruitmentId
    ? await safeGetOne(recruitmentService, recruitmentId)
    : null;
  const ownerId = recruitment?.get?.('author');

  await createNotification(event.dao, {
    user: event.record.get('user'),
    sender: ownerId,
    type: 'recruitment_status_changed',
    title: status === 'accepted'
      ? 'Yêu cầu tham gia được chấp nhận'
      : 'Yêu cầu tham gia bị từ chối',
    body: status === 'accepted'
      ? 'Bạn đã được duyệt tham gia đội.'
      : 'Yêu cầu tham gia đã bị từ chối.',
    target_type: 'recruitment_applicant',
    payload: { recruitmentPostId: recruitmentId, status },
  });
});

onRecordAfterCreate(COLLECTIONS.friendRequests, async (event) => {
  if (event.record.get('status') !== 'pending') return;

  await createNotification(event.dao, {
    user: event.record.get('to_user'),
    sender: event.record.get('from_user'),
    type: 'friend_request_received',
    title: 'Bạn có lời mời kết bạn',
    body: 'Có người vừa gửi lời mời kết bạn.',
    target_type: 'friend_request',
    payload: { requestId: event.record.id },
  });
});

onRecordAfterUpdate(COLLECTIONS.friendRequests, async (event) => {
  const status = event.record.get('status');
  if (!['accepted', 'rejected'].includes(status) || statusChangedTo(event, status) === false) {
    return;
  }

  await createNotification(event.dao, {
    user: event.record.get('from_user'),
    sender: event.record.get('to_user'),
    type: status === 'accepted'
      ? 'friend_request_accepted'
      : 'friend_request_rejected',
    title: status === 'accepted'
      ? 'Lời mời kết bạn đã được chấp nhận'
      : 'Lời mời kết bạn đã bị từ chối',
    body: status === 'accepted'
      ? 'Hai bạn giờ đã là bạn bè.'
      : 'Lời mời kết bạn đã bị từ chối.',
    target_type: 'friend_request',
    payload: { requestId: event.record.id, status },
  });
});
