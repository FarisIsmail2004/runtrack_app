/// Maps an incoming push `type` to the in-app route to open on tap.
/// Goal-related pushes deep-link to the goals screen; the rest go home.
String routeForPushType(String? type) {
  switch (type) {
    case 'goal_achieved':
    case 'weekly_goal':
      return '/goals';
    default:
      return '/';
  }
}
