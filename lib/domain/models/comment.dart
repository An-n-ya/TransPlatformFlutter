import 'user.dart';

class Comment {
  final int id;
  final String content;
  final String date;
  final User user;
  
  Comment(this.id, this.content, this.date, this.user);
}