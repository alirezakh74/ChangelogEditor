#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "ChangeLogManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setOrganizationName("DevSuite");
    app.setOrganizationDomain("devsuite.internal");
    app.setApplicationName("ChangelogManagerPro");

    ChangeLogManager coreEngine;

    QQmlApplicationEngine engine;
    // Bind securely to root context to avoid structural namespace collision resolutions
    engine.rootContext()->setContextProperty("BackendEngine", &coreEngine);

    const QUrl url(QStringLiteral("qrc:/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
