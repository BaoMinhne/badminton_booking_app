from typing import List, Optional


def intensity_value(intensity: Optional[str]) -> int:
    if intensity == "casual":
        return 1
    if intensity == "semi_competitive":
        return 2
    if intensity == "competitive":
        return 3
    return 2  # default trung bình


def jaccard(a: List[str], b: List[str]) -> float:
    set_a = set(a)
    set_b = set(b)
    if not set_a and not set_b:
        return 0.0
    intersection = len(set_a & set_b)
    union = len(set_a | set_b)
    if union == 0:
        return 0.0
    return intersection / union
