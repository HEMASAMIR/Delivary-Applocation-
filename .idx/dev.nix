# To learn more about how to use Nix to configure your environment
# see: https://firebase.google.com/docs/studio/customize-workspace
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"

  # 1. أضفنا Node.js و Flutter للأدوات الأساسية
  packages = [
    pkgs.jdk21
    pkgs.unzip
    pkgs.nodejs_20
    pkgs.flutter
  ];

  # Sets environment variables in the workspace
  env = {};

  idx = {
    # Extensions المهمة لـ Dart و Flutter و Node.js
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
      "christian-kohler.npm-intellisense"
    ];

    workspace = {
      # Runs when a workspace is first created
      onCreate = {
        # تنزيل مكتبات الفلاتر والـ npm أول مرة ينشأ فيها المشروع
        install-dependencies = "flutter pub get && cd backend && npm install";
      };
      
      # 2. تشغيل السيرفر تلقائياً كل مرة تفتح فيها الـ Workspace
      onStart = {
        # تشغيل سيرفر الـ Node.js (تأكد إن اسم المجلد backend)
        run-server = "cd backend && npm run dev"; 
      };
    };

    # Enable previews and customize configuration
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["flutter" "run" "--machine" "-d" "web-server" "--web-hostname" "0.0.0.0" "--web-port" "$PORT"];
          manager = "flutter";
        };
        android = {
          # تشغيل الأندرويد تلقائياً إذا كان المحاكي مدعوم
          command = ["flutter" "run" "--machine" "-d" "android" "-d" "localhost:5555"];
          manager = "flutter";
        };
      };
    };
  };
}