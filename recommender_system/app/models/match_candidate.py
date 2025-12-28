from typing import Optional, Dict, Any
from pydantic import BaseModel

from app.models.user_details import UserDetails


class MatchCandidate(BaseModel):
    user: UserDetails
    score: float
    debug_info: Optional[Dict[str, Any]] = None
