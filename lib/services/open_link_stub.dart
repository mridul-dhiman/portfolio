/// Non-web builds (and the VM the tests run on) have no `window`. Navigation
/// is a no-op rather than a compile error.
void openLink(String href) {}
