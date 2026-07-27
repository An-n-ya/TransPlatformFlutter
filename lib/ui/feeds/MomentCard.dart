import 'package:flutter/material.dart';
import 'package:trans_platform/domain/models/moment.dart';
import 'package:trans_platform/ui/feeds/photo_grid.dart';

class Moments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    return Padding(
      padding: .all(8.0),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Card(
              child: Column(
                children: [
                  ListTile(
                    // leading: Image.asset('assets/images/avatar.jpg'),
                    leading: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar.jpg',
                        width: 40.0,
                        height: 40.0,
                      ),
                    ),
                    title: Text('User Name'),
                    subtitle: Text('2021-01-01'),
                    trailing: Icon(Icons.more_horiz),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 0.0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec egestas  viverra tortor, vel pretium sapien mollis nec. Aliquam ac faucibus eros. Interdum et malesuada fames ac ante ipsum primis in faucibus. Sed  eleifend dignissim sem id venenatis. Vivamus est orci, egestas a nunc  vitae, commodo rhoncus ipsum. Praesent ac accumsan sapien. Orci varius  natoque penatibus et magnis dis parturient montes, nascetur ridiculus  mus. Nullam sit amet lacus diam. Integer at elit tristique, mattis erat  quis, viverra mauris. Curabitur volutpat sapien vel tristique viverra.  Donec fermentum ultrices nulla, maximus pretium lectus mattis eu. Morbi  non orci enim. Maecenas egestas nulla vel vulputate consequat. Nam  aliquet nisl pretium, venenatis sapien a, malesuada mauris. Suspendisse  bibendum ut turpis vitae elementum.',
                        ),
                        PhotoGrid(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: .only(left: 8.0),
                    child: Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.favorite),
                          label: const Text('110'),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.comment),
                          label: const Text('14'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.notifications_sharp),
                title: Text('Notification 2'),
                subtitle: Text('This is a notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MomentsList extends StatelessWidget {
  final List<Moment> moments;
  final ValueChanged<Moment>? onTap;

  const MomentsList({required this.moments, this.onTap, super.key});

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: moments.length,
    itemBuilder: (context, index) => ListTile(
      title: Text(moments[index].user.name),
      subtitle: Text('发布于：${moments[index].date}'),
      onTap: onTap != null ? () => onTap!(moments[index]) : null,
    ),
  );
}
