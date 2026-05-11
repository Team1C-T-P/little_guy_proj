flutter test --coverage

perl "C:\ProgramData\chocolatey\lib\lcov\tools\bin\lcov" `
  --extract coverage/lcov.info `
  "*/lib/models/database.dart" `
  "*/lib/models/route_service.dart" `
  "*/lib/models/step_points_service.dart" `
  "*/lib/utils/achievement_utils.dart" `
  "*/lib/utils/step_counter.dart" `
  "*/lib/views/dress_view.dart" `
  "*/lib/views/header.dart" `
  "*/lib/views/main_page_view.dart" `
  "*/lib/views/nav_bar.dart" `
  "*/lib/views/routes_view.dart" `
  "*/lib/views/settings_view.dart" `
  "*/lib/views/shop_view.dart" `
  "*/lib/views/summary_view.dart" `
  "*/lib/widgets/button.dart" `
  "*/lib/widgets/progress_bar.dart" `
  -o coverage/lcov_filtered.info

perl "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml" `
  coverage/lcov_filtered.info `
  -o coverage/html

start coverage/html/index.html
