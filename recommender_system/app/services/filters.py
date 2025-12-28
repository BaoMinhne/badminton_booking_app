from app.models.user_details import UserDetails


def check_gender_compatibility(me: UserDetails, other: UserDetails) -> bool:
    """
    Kiểm tra giới tính + loại hình thi đấu:
    - Nếu không set match_types -> chấp nhận tất cả.
    - Nếu không có match_type chung -> loại.
    - mixed: phải khác giới (hard filter).
    - singles, doubles: không ràng buộc giới tính ở layer hard filter.
    """

    if not me.match_types:
        return True

    common = set(me.match_types) & set(other.match_types)
    if not common:
        return False

    if "mixed" in common:
        if me.gender and other.gender and me.gender == other.gender:
            return False

    return True
