/****************************************************************************
** Meta object code from reading C++ file 'overlaymanager.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../src/overlaymanager.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'overlaymanager.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.10.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN14OverlayManagerE_t {};
} // unnamed namespace

template <> constexpr inline auto OverlayManager::qt_create_metaobjectdata<qt_meta_tag_ZN14OverlayManagerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "OverlayManager",
        "clockEnabledChanged",
        "",
        "enabled",
        "weatherEnabledChanged",
        "holidayEnabledChanged",
        "currentTimeChanged",
        "time",
        "currentDateChanged",
        "date",
        "activeHolidayChanged",
        "holiday",
        "currentMessageChanged",
        "message",
        "weatherInfoChanged",
        "info",
        "weatherTempChanged",
        "temp",
        "start",
        "stop",
        "sendMessage",
        "text",
        "durationSeconds",
        "clearMessage",
        "updateWeather",
        "updateClock",
        "checkHoliday",
        "processMessageQueue",
        "clockEnabled",
        "weatherEnabled",
        "holidayEnabled",
        "currentTime",
        "currentDate",
        "activeHoliday",
        "currentMessage",
        "weatherInfo",
        "weatherTemp"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'clockEnabledChanged'
        QtMocHelpers::SignalData<void(bool)>(1, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'weatherEnabledChanged'
        QtMocHelpers::SignalData<void(bool)>(4, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'holidayEnabledChanged'
        QtMocHelpers::SignalData<void(bool)>(5, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 3 },
        }}),
        // Signal 'currentTimeChanged'
        QtMocHelpers::SignalData<void(const QString &)>(6, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 7 },
        }}),
        // Signal 'currentDateChanged'
        QtMocHelpers::SignalData<void(const QString &)>(8, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 9 },
        }}),
        // Signal 'activeHolidayChanged'
        QtMocHelpers::SignalData<void(const QString &)>(10, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 11 },
        }}),
        // Signal 'currentMessageChanged'
        QtMocHelpers::SignalData<void(const QString &)>(12, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 13 },
        }}),
        // Signal 'weatherInfoChanged'
        QtMocHelpers::SignalData<void(const QString &)>(14, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 15 },
        }}),
        // Signal 'weatherTempChanged'
        QtMocHelpers::SignalData<void(int)>(16, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 17 },
        }}),
        // Slot 'start'
        QtMocHelpers::SlotData<void()>(18, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'stop'
        QtMocHelpers::SlotData<void()>(19, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'sendMessage'
        QtMocHelpers::SlotData<void(const QString &, int)>(20, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 21 }, { QMetaType::Int, 22 },
        }}),
        // Slot 'sendMessage'
        QtMocHelpers::SlotData<void(const QString &)>(20, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void, {{
            { QMetaType::QString, 21 },
        }}),
        // Slot 'clearMessage'
        QtMocHelpers::SlotData<void()>(23, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'updateWeather'
        QtMocHelpers::SlotData<void()>(24, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'updateClock'
        QtMocHelpers::SlotData<void()>(25, 2, QMC::AccessPrivate, QMetaType::Void),
        // Slot 'checkHoliday'
        QtMocHelpers::SlotData<void()>(26, 2, QMC::AccessPrivate, QMetaType::Void),
        // Slot 'processMessageQueue'
        QtMocHelpers::SlotData<void()>(27, 2, QMC::AccessPrivate, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'clockEnabled'
        QtMocHelpers::PropertyData<bool>(28, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 0),
        // property 'weatherEnabled'
        QtMocHelpers::PropertyData<bool>(29, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 1),
        // property 'holidayEnabled'
        QtMocHelpers::PropertyData<bool>(30, QMetaType::Bool, QMC::DefaultPropertyFlags | QMC::Writable | QMC::StdCppSet, 2),
        // property 'currentTime'
        QtMocHelpers::PropertyData<QString>(31, QMetaType::QString, QMC::DefaultPropertyFlags, 3),
        // property 'currentDate'
        QtMocHelpers::PropertyData<QString>(32, QMetaType::QString, QMC::DefaultPropertyFlags, 4),
        // property 'activeHoliday'
        QtMocHelpers::PropertyData<QString>(33, QMetaType::QString, QMC::DefaultPropertyFlags, 5),
        // property 'currentMessage'
        QtMocHelpers::PropertyData<QString>(34, QMetaType::QString, QMC::DefaultPropertyFlags, 6),
        // property 'weatherInfo'
        QtMocHelpers::PropertyData<QString>(35, QMetaType::QString, QMC::DefaultPropertyFlags, 7),
        // property 'weatherTemp'
        QtMocHelpers::PropertyData<int>(36, QMetaType::Int, QMC::DefaultPropertyFlags, 8),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<OverlayManager, qt_meta_tag_ZN14OverlayManagerE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject OverlayManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN14OverlayManagerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN14OverlayManagerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN14OverlayManagerE_t>.metaTypes,
    nullptr
} };

void OverlayManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<OverlayManager *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->clockEnabledChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 1: _t->weatherEnabledChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 2: _t->holidayEnabledChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 3: _t->currentTimeChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 4: _t->currentDateChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 5: _t->activeHolidayChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 6: _t->currentMessageChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 7: _t->weatherInfoChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 8: _t->weatherTempChanged((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 9: _t->start(); break;
        case 10: _t->stop(); break;
        case 11: _t->sendMessage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 12: _t->sendMessage((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 13: _t->clearMessage(); break;
        case 14: _t->updateWeather(); break;
        case 15: _t->updateClock(); break;
        case 16: _t->checkHoliday(); break;
        case 17: _t->processMessageQueue(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (OverlayManager::*)(bool )>(_a, &OverlayManager::clockEnabledChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (OverlayManager::*)(bool )>(_a, &OverlayManager::weatherEnabledChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (OverlayManager::*)(bool )>(_a, &OverlayManager::holidayEnabledChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (OverlayManager::*)(const QString & )>(_a, &OverlayManager::currentTimeChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (OverlayManager::*)(const QString & )>(_a, &OverlayManager::currentDateChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (OverlayManager::*)(const QString & )>(_a, &OverlayManager::activeHolidayChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (OverlayManager::*)(const QString & )>(_a, &OverlayManager::currentMessageChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (OverlayManager::*)(const QString & )>(_a, &OverlayManager::weatherInfoChanged, 7))
            return;
        if (QtMocHelpers::indexOfMethod<void (OverlayManager::*)(int )>(_a, &OverlayManager::weatherTempChanged, 8))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<bool*>(_v) = _t->clockEnabled(); break;
        case 1: *reinterpret_cast<bool*>(_v) = _t->weatherEnabled(); break;
        case 2: *reinterpret_cast<bool*>(_v) = _t->holidayEnabled(); break;
        case 3: *reinterpret_cast<QString*>(_v) = _t->currentTime(); break;
        case 4: *reinterpret_cast<QString*>(_v) = _t->currentDate(); break;
        case 5: *reinterpret_cast<QString*>(_v) = _t->activeHoliday(); break;
        case 6: *reinterpret_cast<QString*>(_v) = _t->currentMessage(); break;
        case 7: *reinterpret_cast<QString*>(_v) = _t->weatherInfo(); break;
        case 8: *reinterpret_cast<int*>(_v) = _t->weatherTemp(); break;
        default: break;
        }
    }
    if (_c == QMetaObject::WriteProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: _t->setClockEnabled(*reinterpret_cast<bool*>(_v)); break;
        case 1: _t->setWeatherEnabled(*reinterpret_cast<bool*>(_v)); break;
        case 2: _t->setHolidayEnabled(*reinterpret_cast<bool*>(_v)); break;
        default: break;
        }
    }
}

const QMetaObject *OverlayManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *OverlayManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN14OverlayManagerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int OverlayManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 18)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 18;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 18)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 18;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 9;
    }
    return _id;
}

// SIGNAL 0
void OverlayManager::clockEnabledChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1);
}

// SIGNAL 1
void OverlayManager::weatherEnabledChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 1, nullptr, _t1);
}

// SIGNAL 2
void OverlayManager::holidayEnabledChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1);
}

// SIGNAL 3
void OverlayManager::currentTimeChanged(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 3, nullptr, _t1);
}

// SIGNAL 4
void OverlayManager::currentDateChanged(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 4, nullptr, _t1);
}

// SIGNAL 5
void OverlayManager::activeHolidayChanged(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 5, nullptr, _t1);
}

// SIGNAL 6
void OverlayManager::currentMessageChanged(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 6, nullptr, _t1);
}

// SIGNAL 7
void OverlayManager::weatherInfoChanged(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 7, nullptr, _t1);
}

// SIGNAL 8
void OverlayManager::weatherTempChanged(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 8, nullptr, _t1);
}
QT_WARNING_POP
