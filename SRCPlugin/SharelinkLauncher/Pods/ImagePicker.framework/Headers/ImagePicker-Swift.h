// Generated by Apple Swift version 2.1.1 (swiftlang-700.1.101.15 clang-700.1.81)
#pragma clang diagnostic push

#if defined(__has_include) && __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#include <objc/NSObject.h>
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#if defined(__has_include) && __has_include(<uchar.h>)
# include <uchar.h>
#elif !defined(__cplusplus) || __cplusplus < 201103L
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
#endif

typedef struct _NSZone NSZone;

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif

#if defined(__has_attribute) && __has_attribute(objc_runtime_name)
# define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
#else
# define SWIFT_RUNTIME_NAME(X)
#endif
#if defined(__has_attribute) && __has_attribute(swift_name)
# define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
#else
# define SWIFT_COMPILE_NAME(X)
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA
#endif
#if !defined(SWIFT_CLASS)
# if defined(__has_attribute) && __has_attribute(objc_subclassing_restricted) 
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif

#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif

#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif

#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if defined(__has_attribute) && __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum SWIFT_ENUM_EXTRA _name : _type
#endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
#if defined(__has_feature) && __has_feature(modules)
@import UIKit;
@import CoreGraphics;
#endif

#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
@class UIButton;
@class NSCoder;

SWIFT_CLASS("_TtC11ImagePicker19BottomContainerView")
@interface BottomContainerView : UIView
@property (nonatomic, strong) UIButton * __nonnull doneButton;
- (nonnull instancetype)initWithFrame:(CGRect)frame OBJC_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder * __nonnull)aDecoder OBJC_DESIGNATED_INITIALIZER;
@end


@interface BottomContainerView (SWIFT_EXTENSION(ImagePicker))
@end


@interface BottomContainerView (SWIFT_EXTENSION(ImagePicker))
@end

@class UICollectionView;
@class PHAsset;
@class UILabel;

SWIFT_CLASS("_TtC11ImagePicker16ImageGalleryView")
@interface ImageGalleryView : UIView
@property (nonatomic, strong) UICollectionView * __nonnull collectionView;
@property (nonatomic, copy) NSArray<PHAsset *> * __nonnull assets;
@property (nonatomic, strong) UILabel * __nonnull noImagesLabel;
- (nullable instancetype)initWithCoder:(NSCoder * __nonnull)aDecoder OBJC_DESIGNATED_INITIALIZER;
- (void)layoutSubviews;
@end

@class UICollectionViewLayout;
@class NSIndexPath;

@interface ImageGalleryView (SWIFT_EXTENSION(ImagePicker)) <UICollectionViewDelegateFlowLayout>
- (CGSize)collectionView:(UICollectionView * __nonnull)collectionView layout:(UICollectionViewLayout * __nonnull)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath * __nonnull)indexPath;
@end

@class UICollectionViewCell;

@interface ImageGalleryView (SWIFT_EXTENSION(ImagePicker)) <UICollectionViewDelegate, UIScrollViewDelegate>
- (void)collectionView:(UICollectionView * __nonnull)collectionView didSelectItemAtIndexPath:(NSIndexPath * __nonnull)indexPath;
- (void)collectionView:(UICollectionView * __nonnull)collectionView didEndDisplayingCell:(UICollectionViewCell * __nonnull)cell forItemAtIndexPath:(NSIndexPath * __nonnull)indexPath;
@end


@interface ImageGalleryView (SWIFT_EXTENSION(ImagePicker)) <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView * __nonnull)collectionView numberOfItemsInSection:(NSInteger)section;
- (UICollectionViewCell * __nonnull)collectionView:(UICollectionView * __nonnull)collectionView cellForItemAtIndexPath:(NSIndexPath * __nonnull)indexPath;
@end

@class NSBundle;

SWIFT_CLASS("_TtC11ImagePicker21ImagePickerController")
@interface ImagePickerController : UIViewController
@property (nonatomic, strong) ImageGalleryView * __nonnull galleryView;
@property (nonatomic, strong) BottomContainerView * __nonnull bottomContainer;
@property (nonatomic, copy) NSString * __nullable doneButtonTitle;
- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (BOOL)prefersStatusBarHidden;
- (void)collapseGalleryView:(void (^ __nullable)(void))completion;
- (void)showGalleryView;
- (void)expandGalleryView;
- (nonnull instancetype)initWithNibName:(NSString * __nullable)nibNameOrNil bundle:(NSBundle * __nullable)nibBundleOrNil OBJC_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder * __nonnull)aDecoder OBJC_DESIGNATED_INITIALIZER;
@end


@interface ImagePickerController (SWIFT_EXTENSION(ImagePicker))
@end


@interface ImagePickerController (SWIFT_EXTENSION(ImagePicker))
@end


@interface ImagePickerController (SWIFT_EXTENSION(ImagePicker))
@end


@interface ImagePickerController (SWIFT_EXTENSION(ImagePicker))
@end


@interface ImagePickerController (SWIFT_EXTENSION(ImagePicker))
@end

#pragma clang diagnostic pop
