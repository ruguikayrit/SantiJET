// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poz_analiz.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalizKalemi {

 String get id; AnalizKalemTip get tip; String get pozNo; String get tanim; String get olcuBirimi; double get miktar; double get birimFiyati; double get tutar;
/// Create a copy of AnalizKalemi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalizKalemiCopyWith<AnalizKalemi> get copyWith => _$AnalizKalemiCopyWithImpl<AnalizKalemi>(this as AnalizKalemi, _$identity);

  /// Serializes this AnalizKalemi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalizKalemi&&(identical(other.id, id) || other.id == id)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.pozNo, pozNo) || other.pozNo == pozNo)&&(identical(other.tanim, tanim) || other.tanim == tanim)&&(identical(other.olcuBirimi, olcuBirimi) || other.olcuBirimi == olcuBirimi)&&(identical(other.miktar, miktar) || other.miktar == miktar)&&(identical(other.birimFiyati, birimFiyati) || other.birimFiyati == birimFiyati)&&(identical(other.tutar, tutar) || other.tutar == tutar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tip,pozNo,tanim,olcuBirimi,miktar,birimFiyati,tutar);

@override
String toString() {
  return 'AnalizKalemi(id: $id, tip: $tip, pozNo: $pozNo, tanim: $tanim, olcuBirimi: $olcuBirimi, miktar: $miktar, birimFiyati: $birimFiyati, tutar: $tutar)';
}


}

/// @nodoc
abstract mixin class $AnalizKalemiCopyWith<$Res>  {
  factory $AnalizKalemiCopyWith(AnalizKalemi value, $Res Function(AnalizKalemi) _then) = _$AnalizKalemiCopyWithImpl;
@useResult
$Res call({
 String id, AnalizKalemTip tip, String pozNo, String tanim, String olcuBirimi, double miktar, double birimFiyati, double tutar
});




}
/// @nodoc
class _$AnalizKalemiCopyWithImpl<$Res>
    implements $AnalizKalemiCopyWith<$Res> {
  _$AnalizKalemiCopyWithImpl(this._self, this._then);

  final AnalizKalemi _self;
  final $Res Function(AnalizKalemi) _then;

/// Create a copy of AnalizKalemi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tip = null,Object? pozNo = null,Object? tanim = null,Object? olcuBirimi = null,Object? miktar = null,Object? birimFiyati = null,Object? tutar = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as AnalizKalemTip,pozNo: null == pozNo ? _self.pozNo : pozNo // ignore: cast_nullable_to_non_nullable
as String,tanim: null == tanim ? _self.tanim : tanim // ignore: cast_nullable_to_non_nullable
as String,olcuBirimi: null == olcuBirimi ? _self.olcuBirimi : olcuBirimi // ignore: cast_nullable_to_non_nullable
as String,miktar: null == miktar ? _self.miktar : miktar // ignore: cast_nullable_to_non_nullable
as double,birimFiyati: null == birimFiyati ? _self.birimFiyati : birimFiyati // ignore: cast_nullable_to_non_nullable
as double,tutar: null == tutar ? _self.tutar : tutar // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalizKalemi].
extension AnalizKalemiPatterns on AnalizKalemi {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalizKalemi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalizKalemi() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalizKalemi value)  $default,){
final _that = this;
switch (_that) {
case _AnalizKalemi():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalizKalemi value)?  $default,){
final _that = this;
switch (_that) {
case _AnalizKalemi() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AnalizKalemTip tip,  String pozNo,  String tanim,  String olcuBirimi,  double miktar,  double birimFiyati,  double tutar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalizKalemi() when $default != null:
return $default(_that.id,_that.tip,_that.pozNo,_that.tanim,_that.olcuBirimi,_that.miktar,_that.birimFiyati,_that.tutar);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AnalizKalemTip tip,  String pozNo,  String tanim,  String olcuBirimi,  double miktar,  double birimFiyati,  double tutar)  $default,) {final _that = this;
switch (_that) {
case _AnalizKalemi():
return $default(_that.id,_that.tip,_that.pozNo,_that.tanim,_that.olcuBirimi,_that.miktar,_that.birimFiyati,_that.tutar);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AnalizKalemTip tip,  String pozNo,  String tanim,  String olcuBirimi,  double miktar,  double birimFiyati,  double tutar)?  $default,) {final _that = this;
switch (_that) {
case _AnalizKalemi() when $default != null:
return $default(_that.id,_that.tip,_that.pozNo,_that.tanim,_that.olcuBirimi,_that.miktar,_that.birimFiyati,_that.tutar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalizKalemi implements AnalizKalemi {
  const _AnalizKalemi({required this.id, required this.tip, required this.pozNo, required this.tanim, required this.olcuBirimi, required this.miktar, required this.birimFiyati, required this.tutar});
  factory _AnalizKalemi.fromJson(Map<String, dynamic> json) => _$AnalizKalemiFromJson(json);

@override final  String id;
@override final  AnalizKalemTip tip;
@override final  String pozNo;
@override final  String tanim;
@override final  String olcuBirimi;
@override final  double miktar;
@override final  double birimFiyati;
@override final  double tutar;

/// Create a copy of AnalizKalemi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalizKalemiCopyWith<_AnalizKalemi> get copyWith => __$AnalizKalemiCopyWithImpl<_AnalizKalemi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalizKalemiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalizKalemi&&(identical(other.id, id) || other.id == id)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.pozNo, pozNo) || other.pozNo == pozNo)&&(identical(other.tanim, tanim) || other.tanim == tanim)&&(identical(other.olcuBirimi, olcuBirimi) || other.olcuBirimi == olcuBirimi)&&(identical(other.miktar, miktar) || other.miktar == miktar)&&(identical(other.birimFiyati, birimFiyati) || other.birimFiyati == birimFiyati)&&(identical(other.tutar, tutar) || other.tutar == tutar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tip,pozNo,tanim,olcuBirimi,miktar,birimFiyati,tutar);

@override
String toString() {
  return 'AnalizKalemi(id: $id, tip: $tip, pozNo: $pozNo, tanim: $tanim, olcuBirimi: $olcuBirimi, miktar: $miktar, birimFiyati: $birimFiyati, tutar: $tutar)';
}


}

/// @nodoc
abstract mixin class _$AnalizKalemiCopyWith<$Res> implements $AnalizKalemiCopyWith<$Res> {
  factory _$AnalizKalemiCopyWith(_AnalizKalemi value, $Res Function(_AnalizKalemi) _then) = __$AnalizKalemiCopyWithImpl;
@override @useResult
$Res call({
 String id, AnalizKalemTip tip, String pozNo, String tanim, String olcuBirimi, double miktar, double birimFiyati, double tutar
});




}
/// @nodoc
class __$AnalizKalemiCopyWithImpl<$Res>
    implements _$AnalizKalemiCopyWith<$Res> {
  __$AnalizKalemiCopyWithImpl(this._self, this._then);

  final _AnalizKalemi _self;
  final $Res Function(_AnalizKalemi) _then;

/// Create a copy of AnalizKalemi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tip = null,Object? pozNo = null,Object? tanim = null,Object? olcuBirimi = null,Object? miktar = null,Object? birimFiyati = null,Object? tutar = null,}) {
  return _then(_AnalizKalemi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as AnalizKalemTip,pozNo: null == pozNo ? _self.pozNo : pozNo // ignore: cast_nullable_to_non_nullable
as String,tanim: null == tanim ? _self.tanim : tanim // ignore: cast_nullable_to_non_nullable
as String,olcuBirimi: null == olcuBirimi ? _self.olcuBirimi : olcuBirimi // ignore: cast_nullable_to_non_nullable
as String,miktar: null == miktar ? _self.miktar : miktar // ignore: cast_nullable_to_non_nullable
as double,birimFiyati: null == birimFiyati ? _self.birimFiyati : birimFiyati // ignore: cast_nullable_to_non_nullable
as double,tutar: null == tutar ? _self.tutar : tutar // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PozAnaliz {

 String get id; String get pozNo; String get analizAdi; String get olcuBirimi; String get kategori; List<AnalizKalemi> get kalemler; String get pozTarifi; String get yapimSartlari; String get olcusu; double get malzemeIscilikToplami; double get yukleniciKarOrani; double get yukleniciKarTutari; double get birimFiyati; String get olusturmaTarihi; String get guncellemeTarihi; KaynakTip get kaynakTip; AnalizDiscipline? get discipline; String? get notlar;
/// Create a copy of PozAnaliz
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PozAnalizCopyWith<PozAnaliz> get copyWith => _$PozAnalizCopyWithImpl<PozAnaliz>(this as PozAnaliz, _$identity);

  /// Serializes this PozAnaliz to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PozAnaliz&&(identical(other.id, id) || other.id == id)&&(identical(other.pozNo, pozNo) || other.pozNo == pozNo)&&(identical(other.analizAdi, analizAdi) || other.analizAdi == analizAdi)&&(identical(other.olcuBirimi, olcuBirimi) || other.olcuBirimi == olcuBirimi)&&(identical(other.kategori, kategori) || other.kategori == kategori)&&const DeepCollectionEquality().equals(other.kalemler, kalemler)&&(identical(other.pozTarifi, pozTarifi) || other.pozTarifi == pozTarifi)&&(identical(other.yapimSartlari, yapimSartlari) || other.yapimSartlari == yapimSartlari)&&(identical(other.olcusu, olcusu) || other.olcusu == olcusu)&&(identical(other.malzemeIscilikToplami, malzemeIscilikToplami) || other.malzemeIscilikToplami == malzemeIscilikToplami)&&(identical(other.yukleniciKarOrani, yukleniciKarOrani) || other.yukleniciKarOrani == yukleniciKarOrani)&&(identical(other.yukleniciKarTutari, yukleniciKarTutari) || other.yukleniciKarTutari == yukleniciKarTutari)&&(identical(other.birimFiyati, birimFiyati) || other.birimFiyati == birimFiyati)&&(identical(other.olusturmaTarihi, olusturmaTarihi) || other.olusturmaTarihi == olusturmaTarihi)&&(identical(other.guncellemeTarihi, guncellemeTarihi) || other.guncellemeTarihi == guncellemeTarihi)&&(identical(other.kaynakTip, kaynakTip) || other.kaynakTip == kaynakTip)&&(identical(other.discipline, discipline) || other.discipline == discipline)&&(identical(other.notlar, notlar) || other.notlar == notlar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pozNo,analizAdi,olcuBirimi,kategori,const DeepCollectionEquality().hash(kalemler),pozTarifi,yapimSartlari,olcusu,malzemeIscilikToplami,yukleniciKarOrani,yukleniciKarTutari,birimFiyati,olusturmaTarihi,guncellemeTarihi,kaynakTip,discipline,notlar);

@override
String toString() {
  return 'PozAnaliz(id: $id, pozNo: $pozNo, analizAdi: $analizAdi, olcuBirimi: $olcuBirimi, kategori: $kategori, kalemler: $kalemler, pozTarifi: $pozTarifi, yapimSartlari: $yapimSartlari, olcusu: $olcusu, malzemeIscilikToplami: $malzemeIscilikToplami, yukleniciKarOrani: $yukleniciKarOrani, yukleniciKarTutari: $yukleniciKarTutari, birimFiyati: $birimFiyati, olusturmaTarihi: $olusturmaTarihi, guncellemeTarihi: $guncellemeTarihi, kaynakTip: $kaynakTip, discipline: $discipline, notlar: $notlar)';
}


}

/// @nodoc
abstract mixin class $PozAnalizCopyWith<$Res>  {
  factory $PozAnalizCopyWith(PozAnaliz value, $Res Function(PozAnaliz) _then) = _$PozAnalizCopyWithImpl;
@useResult
$Res call({
 String id, String pozNo, String analizAdi, String olcuBirimi, String kategori, List<AnalizKalemi> kalemler, String pozTarifi, String yapimSartlari, String olcusu, double malzemeIscilikToplami, double yukleniciKarOrani, double yukleniciKarTutari, double birimFiyati, String olusturmaTarihi, String guncellemeTarihi, KaynakTip kaynakTip, AnalizDiscipline? discipline, String? notlar
});




}
/// @nodoc
class _$PozAnalizCopyWithImpl<$Res>
    implements $PozAnalizCopyWith<$Res> {
  _$PozAnalizCopyWithImpl(this._self, this._then);

  final PozAnaliz _self;
  final $Res Function(PozAnaliz) _then;

/// Create a copy of PozAnaliz
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pozNo = null,Object? analizAdi = null,Object? olcuBirimi = null,Object? kategori = null,Object? kalemler = null,Object? pozTarifi = null,Object? yapimSartlari = null,Object? olcusu = null,Object? malzemeIscilikToplami = null,Object? yukleniciKarOrani = null,Object? yukleniciKarTutari = null,Object? birimFiyati = null,Object? olusturmaTarihi = null,Object? guncellemeTarihi = null,Object? kaynakTip = null,Object? discipline = freezed,Object? notlar = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pozNo: null == pozNo ? _self.pozNo : pozNo // ignore: cast_nullable_to_non_nullable
as String,analizAdi: null == analizAdi ? _self.analizAdi : analizAdi // ignore: cast_nullable_to_non_nullable
as String,olcuBirimi: null == olcuBirimi ? _self.olcuBirimi : olcuBirimi // ignore: cast_nullable_to_non_nullable
as String,kategori: null == kategori ? _self.kategori : kategori // ignore: cast_nullable_to_non_nullable
as String,kalemler: null == kalemler ? _self.kalemler : kalemler // ignore: cast_nullable_to_non_nullable
as List<AnalizKalemi>,pozTarifi: null == pozTarifi ? _self.pozTarifi : pozTarifi // ignore: cast_nullable_to_non_nullable
as String,yapimSartlari: null == yapimSartlari ? _self.yapimSartlari : yapimSartlari // ignore: cast_nullable_to_non_nullable
as String,olcusu: null == olcusu ? _self.olcusu : olcusu // ignore: cast_nullable_to_non_nullable
as String,malzemeIscilikToplami: null == malzemeIscilikToplami ? _self.malzemeIscilikToplami : malzemeIscilikToplami // ignore: cast_nullable_to_non_nullable
as double,yukleniciKarOrani: null == yukleniciKarOrani ? _self.yukleniciKarOrani : yukleniciKarOrani // ignore: cast_nullable_to_non_nullable
as double,yukleniciKarTutari: null == yukleniciKarTutari ? _self.yukleniciKarTutari : yukleniciKarTutari // ignore: cast_nullable_to_non_nullable
as double,birimFiyati: null == birimFiyati ? _self.birimFiyati : birimFiyati // ignore: cast_nullable_to_non_nullable
as double,olusturmaTarihi: null == olusturmaTarihi ? _self.olusturmaTarihi : olusturmaTarihi // ignore: cast_nullable_to_non_nullable
as String,guncellemeTarihi: null == guncellemeTarihi ? _self.guncellemeTarihi : guncellemeTarihi // ignore: cast_nullable_to_non_nullable
as String,kaynakTip: null == kaynakTip ? _self.kaynakTip : kaynakTip // ignore: cast_nullable_to_non_nullable
as KaynakTip,discipline: freezed == discipline ? _self.discipline : discipline // ignore: cast_nullable_to_non_nullable
as AnalizDiscipline?,notlar: freezed == notlar ? _self.notlar : notlar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PozAnaliz].
extension PozAnalizPatterns on PozAnaliz {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PozAnaliz value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PozAnaliz() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PozAnaliz value)  $default,){
final _that = this;
switch (_that) {
case _PozAnaliz():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PozAnaliz value)?  $default,){
final _that = this;
switch (_that) {
case _PozAnaliz() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pozNo,  String analizAdi,  String olcuBirimi,  String kategori,  List<AnalizKalemi> kalemler,  String pozTarifi,  String yapimSartlari,  String olcusu,  double malzemeIscilikToplami,  double yukleniciKarOrani,  double yukleniciKarTutari,  double birimFiyati,  String olusturmaTarihi,  String guncellemeTarihi,  KaynakTip kaynakTip,  AnalizDiscipline? discipline,  String? notlar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PozAnaliz() when $default != null:
return $default(_that.id,_that.pozNo,_that.analizAdi,_that.olcuBirimi,_that.kategori,_that.kalemler,_that.pozTarifi,_that.yapimSartlari,_that.olcusu,_that.malzemeIscilikToplami,_that.yukleniciKarOrani,_that.yukleniciKarTutari,_that.birimFiyati,_that.olusturmaTarihi,_that.guncellemeTarihi,_that.kaynakTip,_that.discipline,_that.notlar);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pozNo,  String analizAdi,  String olcuBirimi,  String kategori,  List<AnalizKalemi> kalemler,  String pozTarifi,  String yapimSartlari,  String olcusu,  double malzemeIscilikToplami,  double yukleniciKarOrani,  double yukleniciKarTutari,  double birimFiyati,  String olusturmaTarihi,  String guncellemeTarihi,  KaynakTip kaynakTip,  AnalizDiscipline? discipline,  String? notlar)  $default,) {final _that = this;
switch (_that) {
case _PozAnaliz():
return $default(_that.id,_that.pozNo,_that.analizAdi,_that.olcuBirimi,_that.kategori,_that.kalemler,_that.pozTarifi,_that.yapimSartlari,_that.olcusu,_that.malzemeIscilikToplami,_that.yukleniciKarOrani,_that.yukleniciKarTutari,_that.birimFiyati,_that.olusturmaTarihi,_that.guncellemeTarihi,_that.kaynakTip,_that.discipline,_that.notlar);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pozNo,  String analizAdi,  String olcuBirimi,  String kategori,  List<AnalizKalemi> kalemler,  String pozTarifi,  String yapimSartlari,  String olcusu,  double malzemeIscilikToplami,  double yukleniciKarOrani,  double yukleniciKarTutari,  double birimFiyati,  String olusturmaTarihi,  String guncellemeTarihi,  KaynakTip kaynakTip,  AnalizDiscipline? discipline,  String? notlar)?  $default,) {final _that = this;
switch (_that) {
case _PozAnaliz() when $default != null:
return $default(_that.id,_that.pozNo,_that.analizAdi,_that.olcuBirimi,_that.kategori,_that.kalemler,_that.pozTarifi,_that.yapimSartlari,_that.olcusu,_that.malzemeIscilikToplami,_that.yukleniciKarOrani,_that.yukleniciKarTutari,_that.birimFiyati,_that.olusturmaTarihi,_that.guncellemeTarihi,_that.kaynakTip,_that.discipline,_that.notlar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PozAnaliz implements PozAnaliz {
  const _PozAnaliz({required this.id, required this.pozNo, required this.analizAdi, required this.olcuBirimi, required this.kategori, final  List<AnalizKalemi> kalemler = const <AnalizKalemi>[], this.pozTarifi = '', this.yapimSartlari = '', this.olcusu = '', this.malzemeIscilikToplami = 0, this.yukleniciKarOrani = 0, this.yukleniciKarTutari = 0, this.birimFiyati = 0, this.olusturmaTarihi = '', this.guncellemeTarihi = '', this.kaynakTip = KaynakTip.sistem, this.discipline, this.notlar}): _kalemler = kalemler;
  factory _PozAnaliz.fromJson(Map<String, dynamic> json) => _$PozAnalizFromJson(json);

@override final  String id;
@override final  String pozNo;
@override final  String analizAdi;
@override final  String olcuBirimi;
@override final  String kategori;
 final  List<AnalizKalemi> _kalemler;
@override@JsonKey() List<AnalizKalemi> get kalemler {
  if (_kalemler is EqualUnmodifiableListView) return _kalemler;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_kalemler);
}

@override@JsonKey() final  String pozTarifi;
@override@JsonKey() final  String yapimSartlari;
@override@JsonKey() final  String olcusu;
@override@JsonKey() final  double malzemeIscilikToplami;
@override@JsonKey() final  double yukleniciKarOrani;
@override@JsonKey() final  double yukleniciKarTutari;
@override@JsonKey() final  double birimFiyati;
@override@JsonKey() final  String olusturmaTarihi;
@override@JsonKey() final  String guncellemeTarihi;
@override@JsonKey() final  KaynakTip kaynakTip;
@override final  AnalizDiscipline? discipline;
@override final  String? notlar;

/// Create a copy of PozAnaliz
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PozAnalizCopyWith<_PozAnaliz> get copyWith => __$PozAnalizCopyWithImpl<_PozAnaliz>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PozAnalizToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PozAnaliz&&(identical(other.id, id) || other.id == id)&&(identical(other.pozNo, pozNo) || other.pozNo == pozNo)&&(identical(other.analizAdi, analizAdi) || other.analizAdi == analizAdi)&&(identical(other.olcuBirimi, olcuBirimi) || other.olcuBirimi == olcuBirimi)&&(identical(other.kategori, kategori) || other.kategori == kategori)&&const DeepCollectionEquality().equals(other._kalemler, _kalemler)&&(identical(other.pozTarifi, pozTarifi) || other.pozTarifi == pozTarifi)&&(identical(other.yapimSartlari, yapimSartlari) || other.yapimSartlari == yapimSartlari)&&(identical(other.olcusu, olcusu) || other.olcusu == olcusu)&&(identical(other.malzemeIscilikToplami, malzemeIscilikToplami) || other.malzemeIscilikToplami == malzemeIscilikToplami)&&(identical(other.yukleniciKarOrani, yukleniciKarOrani) || other.yukleniciKarOrani == yukleniciKarOrani)&&(identical(other.yukleniciKarTutari, yukleniciKarTutari) || other.yukleniciKarTutari == yukleniciKarTutari)&&(identical(other.birimFiyati, birimFiyati) || other.birimFiyati == birimFiyati)&&(identical(other.olusturmaTarihi, olusturmaTarihi) || other.olusturmaTarihi == olusturmaTarihi)&&(identical(other.guncellemeTarihi, guncellemeTarihi) || other.guncellemeTarihi == guncellemeTarihi)&&(identical(other.kaynakTip, kaynakTip) || other.kaynakTip == kaynakTip)&&(identical(other.discipline, discipline) || other.discipline == discipline)&&(identical(other.notlar, notlar) || other.notlar == notlar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pozNo,analizAdi,olcuBirimi,kategori,const DeepCollectionEquality().hash(_kalemler),pozTarifi,yapimSartlari,olcusu,malzemeIscilikToplami,yukleniciKarOrani,yukleniciKarTutari,birimFiyati,olusturmaTarihi,guncellemeTarihi,kaynakTip,discipline,notlar);

@override
String toString() {
  return 'PozAnaliz(id: $id, pozNo: $pozNo, analizAdi: $analizAdi, olcuBirimi: $olcuBirimi, kategori: $kategori, kalemler: $kalemler, pozTarifi: $pozTarifi, yapimSartlari: $yapimSartlari, olcusu: $olcusu, malzemeIscilikToplami: $malzemeIscilikToplami, yukleniciKarOrani: $yukleniciKarOrani, yukleniciKarTutari: $yukleniciKarTutari, birimFiyati: $birimFiyati, olusturmaTarihi: $olusturmaTarihi, guncellemeTarihi: $guncellemeTarihi, kaynakTip: $kaynakTip, discipline: $discipline, notlar: $notlar)';
}


}

/// @nodoc
abstract mixin class _$PozAnalizCopyWith<$Res> implements $PozAnalizCopyWith<$Res> {
  factory _$PozAnalizCopyWith(_PozAnaliz value, $Res Function(_PozAnaliz) _then) = __$PozAnalizCopyWithImpl;
@override @useResult
$Res call({
 String id, String pozNo, String analizAdi, String olcuBirimi, String kategori, List<AnalizKalemi> kalemler, String pozTarifi, String yapimSartlari, String olcusu, double malzemeIscilikToplami, double yukleniciKarOrani, double yukleniciKarTutari, double birimFiyati, String olusturmaTarihi, String guncellemeTarihi, KaynakTip kaynakTip, AnalizDiscipline? discipline, String? notlar
});




}
/// @nodoc
class __$PozAnalizCopyWithImpl<$Res>
    implements _$PozAnalizCopyWith<$Res> {
  __$PozAnalizCopyWithImpl(this._self, this._then);

  final _PozAnaliz _self;
  final $Res Function(_PozAnaliz) _then;

/// Create a copy of PozAnaliz
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pozNo = null,Object? analizAdi = null,Object? olcuBirimi = null,Object? kategori = null,Object? kalemler = null,Object? pozTarifi = null,Object? yapimSartlari = null,Object? olcusu = null,Object? malzemeIscilikToplami = null,Object? yukleniciKarOrani = null,Object? yukleniciKarTutari = null,Object? birimFiyati = null,Object? olusturmaTarihi = null,Object? guncellemeTarihi = null,Object? kaynakTip = null,Object? discipline = freezed,Object? notlar = freezed,}) {
  return _then(_PozAnaliz(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pozNo: null == pozNo ? _self.pozNo : pozNo // ignore: cast_nullable_to_non_nullable
as String,analizAdi: null == analizAdi ? _self.analizAdi : analizAdi // ignore: cast_nullable_to_non_nullable
as String,olcuBirimi: null == olcuBirimi ? _self.olcuBirimi : olcuBirimi // ignore: cast_nullable_to_non_nullable
as String,kategori: null == kategori ? _self.kategori : kategori // ignore: cast_nullable_to_non_nullable
as String,kalemler: null == kalemler ? _self._kalemler : kalemler // ignore: cast_nullable_to_non_nullable
as List<AnalizKalemi>,pozTarifi: null == pozTarifi ? _self.pozTarifi : pozTarifi // ignore: cast_nullable_to_non_nullable
as String,yapimSartlari: null == yapimSartlari ? _self.yapimSartlari : yapimSartlari // ignore: cast_nullable_to_non_nullable
as String,olcusu: null == olcusu ? _self.olcusu : olcusu // ignore: cast_nullable_to_non_nullable
as String,malzemeIscilikToplami: null == malzemeIscilikToplami ? _self.malzemeIscilikToplami : malzemeIscilikToplami // ignore: cast_nullable_to_non_nullable
as double,yukleniciKarOrani: null == yukleniciKarOrani ? _self.yukleniciKarOrani : yukleniciKarOrani // ignore: cast_nullable_to_non_nullable
as double,yukleniciKarTutari: null == yukleniciKarTutari ? _self.yukleniciKarTutari : yukleniciKarTutari // ignore: cast_nullable_to_non_nullable
as double,birimFiyati: null == birimFiyati ? _self.birimFiyati : birimFiyati // ignore: cast_nullable_to_non_nullable
as double,olusturmaTarihi: null == olusturmaTarihi ? _self.olusturmaTarihi : olusturmaTarihi // ignore: cast_nullable_to_non_nullable
as String,guncellemeTarihi: null == guncellemeTarihi ? _self.guncellemeTarihi : guncellemeTarihi // ignore: cast_nullable_to_non_nullable
as String,kaynakTip: null == kaynakTip ? _self.kaynakTip : kaynakTip // ignore: cast_nullable_to_non_nullable
as KaynakTip,discipline: freezed == discipline ? _self.discipline : discipline // ignore: cast_nullable_to_non_nullable
as AnalizDiscipline?,notlar: freezed == notlar ? _self.notlar : notlar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
