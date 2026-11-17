#include <QGuiApplication>
#include <QCoreApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QIcon>

#ifdef Q_OS_WIN
#include <winsock2.h>
#include <shobjidl.h>
#endif

#include "App/SessionManager.hpp"

#include "app_environment.h"
#include "import_qml_components_plugins.h"
#include "import_qml_plugins.h"

int main(int argc, char *argv[]) {
#ifdef Q_OS_WIN
  const HRESULT appUserModelIdResult =
      SetCurrentProcessExplicitAppUserModelID(
          L"Knapp-Ausbildung.ScriptExecutorApp");
  if (FAILED(appUserModelIdResult)) {
    qWarning() << "Could not set Windows AppUserModelID:"
               << appUserModelIdResult;
  }
#endif

  // Qt-Umgebung vorbereiten.
  // Das ist für die richtige Asset-/Resource-Initialisierung wichtig.
  set_qt_environment();

  QGuiApplication app(argc, argv);
  QGuiApplication::setWindowIcon(QIcon(QStringLiteral(":/resources/app_icon.png")));
  QCoreApplication::setApplicationVersion(
      QStringLiteral(SCRIPT_EXECUTOR_APP_VERSION));

  // Erstellen einer Session
  SessionManager sessionManager;
  sessionManager.addSession();

  // Engine für QML
  QQmlApplicationEngine engine;

  const QString configBase = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);

  if (configBase.isEmpty()) {
    qCritical() << "Kein Kofnigurationsverzeichnis verfügbar!";
    return 1;
  }

  const QString configDir = QDir(configBase).filePath("ScriptExecutorApp");

  if (!QDir().mkpath(configDir)) {
    qCritical() << "Konfigurationsverzeichnis konnte nicht erstellt werden: " << configDir;
    return 1;
  }

  const QString settingsFile = QDir(configDir).filePath("settings.ini");

  engine.rootContext()->setContextProperty("settingsFile", settingsFile);

  // Wichtig: Das Objekt als Kontextproperty in QML einhängen.
  // Dadurch kann QML auf sessionManager zugreifen
  engine.rootContext()->setContextProperty("sessionManager", &sessionManager);

  // QML-Datei laden
  const QUrl url(u"qrc:/qt/qml/Main/main.qml"_qs);
  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreated, &app,
      [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
          QCoreApplication::exit(-1);
      },
      Qt::QueuedConnection);

  engine.addImportPath(QCoreApplication::applicationDirPath() + "/qml");
  engine.addImportPath(":/");

  engine.load(url);

  if (engine.rootObjects().isEmpty()) {
    return -1;
  }

  return app.exec();
}