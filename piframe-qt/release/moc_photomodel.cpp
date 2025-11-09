/****************************************************************************
** Meta object code from reading C++ file 'photomodel.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../src/photomodel.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'photomodel.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN10PhotoModelE_t {};
} // unnamed namespace

template <> constexpr inline auto PhotoModel::qt_create_metaobjectdata<qt_meta_tag_ZN10PhotoModelE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "PhotoModel",
        "currentPhotoChanged",
        "",
        "photo",
        "photoCountChanged",
        "count",
        "currentIndexChanged",
        "index",
        "isPlayingChanged",
        "playing",
        "photoSourceChanged",
        "source",
        "photosLoaded",
        "photoLoadError",
        "error",
        "start",
        "stop",
        "pause",
        "resume",
        "next",
        "previous",
        "loadPhotos",
        "refreshPhotos",
        "advancePhoto",
        "onDirectoryChanged",
        "path",
        "currentPhoto",
        "photoCount",
        "currentIndex",
        "isPlaying",
        "photoSource"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'currentPhotoChanged'
        QtMocHelpers::SignalData<void(const QString &)>(1, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 },
        }}),
        // Signal 'photoCountChanged'
        QtMocHelpers::SignalData<void(int)>(4, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 5 },
        }}),
        // Signal 'currentIndexChanged'
        QtMocHelpers::SignalData<void(int)>(6, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 7 },
        }}),
        // Signal 'isPlayingChanged'
        QtMocHelpers::SignalData<void(bool)>(8, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 9 },
        }}),
        // Signal 'photoSourceChanged'
        QtMocHelpers::SignalData<void(const QString &)>(10, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 11 },
        }}),
        // Signal 'photosLoaded'
        QtMocHelpers::SignalData<void()>(12, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'photoLoadError'
        QtMocHelpers::SignalData<void(const QString &)>(13, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 14 },
        }}),
        // Slot 'start'
        QtMocHelpers::SlotData<void()>(15, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'stop'
        QtMocHelpers::SlotData<void()>(16, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'pause'
        QtMocHelpers::SlotData<void()>(17, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'resume'
        QtMocHelpers::SlotData<void()>(18, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'next'
        QtMocHelpers::SlotData<void()>(19, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'previous'
        QtMocHelpers::SlotData<void()>(20, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'loadPhotos'
        QtMocHelpers::SlotData<void()>(21, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'refreshPhotos'
        QtMocHelpers::SlotData<void()>(22, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'advancePhoto'
        QtMocHelpers::SlotData<void()>(23, 2, QMC::AccessPrivate, QMetaType::Void),
        // Slot 'onDirectoryChanged'
        QtMocHelpers::SlotData<void(const QString &)>(24, 2, QMC::AccessPrivate, QMetaType::Void, {{
            { QMetaType::QString, 25 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'currentPhoto'
        QtMocHelpers::PropertyData<QString>(26, QMetaType::QString, QMC::DefaultPropertyFlags, 0),
        // property 'photoCount'
        QtMocHelpers::PropertyData<int>(27, QMetaType::Int, QMC::DefaultPropertyFlags, 1),
        // property 'currentIndex'
        QtMocHelpers::PropertyData<int>(28, QMetaType::Int, QMC::DefaultPropertyFlags, 2),
        // property 'isPlaying'
        QtMocHelpers::PropertyData<bool>(29, QMetaType::Bool, QMC::DefaultPropertyFlags, 3),
        // property 'photoSource'
        QtMocHelpers::PropertyData<QString>(30, QMetaType::QString, QMC::DefaultPropertyFlags, 4),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<PhotoModel, qt_meta_tag_ZN10PhotoModelE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject PhotoModel::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10PhotoModelE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10PhotoModelE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN10PhotoModelE_t>.metaTypes,
    nullptr
} };

void PhotoModel::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<PhotoModel *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->currentPhotoChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 1: _t->photoCountChanged((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 2: _t->currentIndexChanged((*reinterpret_cast<std::add_pointer_t<int>>(_a[1]))); break;
        case 3: _t->isPlayingChanged((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 4: _t->photoSourceChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 5: _t->photosLoaded(); break;
        case 6: _t->photoLoadError((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 7: _t->start(); break;
        case 8: _t->stop(); break;
        case 9: _t->pause(); break;
        case 10: _t->resume(); break;
        case 11: _t->next(); break;
        case 12: _t->previous(); break;
        case 13: _t->loadPhotos(); break;
        case 14: _t->refreshPhotos(); break;
        case 15: _t->advancePhoto(); break;
        case 16: _t->onDirectoryChanged((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (PhotoModel::*)(const QString & )>(_a, &PhotoModel::currentPhotoChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (PhotoModel::*)(int )>(_a, &PhotoModel::photoCountChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (PhotoModel::*)(int )>(_a, &PhotoModel::currentIndexChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (PhotoModel::*)(bool )>(_a, &PhotoModel::isPlayingChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (PhotoModel::*)(const QString & )>(_a, &PhotoModel::photoSourceChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (PhotoModel::*)()>(_a, &PhotoModel::photosLoaded, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (PhotoModel::*)(const QString & )>(_a, &PhotoModel::photoLoadError, 6))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QString*>(_v) = _t->currentPhoto(); break;
        case 1: *reinterpret_cast<int*>(_v) = _t->photoCount(); break;
        case 2: *reinterpret_cast<int*>(_v) = _t->currentIndex(); break;
        case 3: *reinterpret_cast<bool*>(_v) = _t->isPlaying(); break;
        case 4: *reinterpret_cast<QString*>(_v) = _t->photoSource(); break;
        default: break;
        }
    }
}

const QMetaObject *PhotoModel::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *PhotoModel::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN10PhotoModelE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int PhotoModel::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 17)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 17;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 17)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 17;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 5;
    }
    return _id;
}

// SIGNAL 0
void PhotoModel::currentPhotoChanged(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1);
}

// SIGNAL 1
void PhotoModel::photoCountChanged(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 1, nullptr, _t1);
}

// SIGNAL 2
void PhotoModel::currentIndexChanged(int _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1);
}

// SIGNAL 3
void PhotoModel::isPlayingChanged(bool _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 3, nullptr, _t1);
}

// SIGNAL 4
void PhotoModel::photoSourceChanged(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 4, nullptr, _t1);
}

// SIGNAL 5
void PhotoModel::photosLoaded()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void PhotoModel::photoLoadError(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 6, nullptr, _t1);
}
QT_WARNING_POP
