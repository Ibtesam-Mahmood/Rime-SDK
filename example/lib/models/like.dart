class Like{

  final String userInfoId;
  final String postID;

  Like(this.userInfoId, this.postID);

  factory Like.fromJson(Map<String, dynamic> json){
    return Like(
      json['userInfoId'],
      json['postId']
    );
  }

  @override
  bool operator == (other){
    return (postID == other.postID && userInfoId == other.userInfoId);
  }
}