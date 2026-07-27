import 'user.dart';
import 'comment.dart';

class Moment {
  final int id;
  final String date;
  // final String location;
  final User user;
  final int likeCount;
  final int commentsCount;
  final List<Comment> comments;
  final String contentText;
  final List<Picture> contentPictures;
  
  Moment(this.id, this.date, this.user, this.likeCount, this.commentsCount, this.comments, this.contentText, this.contentPictures);
}


class Picture {
  final String url;
  
  Picture(this.url);
}