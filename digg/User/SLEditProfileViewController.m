//
//  SLEditProfileViewController.m
//  digg
//
//  Created by Tim Bao on 2025/1/7.
//

#import "SLEditProfileViewController.h"
#import "SLGeneralMacro.h"
#import "Masonry.h"
#import "SLProfilePageViewModel.h"
#import "SVProgressHUD.h"
#import <SDWebImage/SDWebImage.h>
#import "SLColorManager.h"

@interface SLEditProfileViewController () <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIButton *leftBackButton;
@property (nonatomic, strong) UIButton *saveBackButton;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIImageView* headerImageView;
@property (nonatomic, strong) UIImageView* avatarImageView;
@property (nonatomic, strong) UIImageView* addAvatarImageView;

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UITextField *nameTextField;

@property (nonatomic, strong) UILabel *briefLabel;
@property (nonatomic, strong) UITextView *briefTextView;

@property (nonatomic, strong) SLProfilePageViewModel *viewModel;
@property (nonatomic, assign) NSInteger avatarOrBg;
@property (nonatomic, strong) UIImage* avatarImage;
@property (nonatomic, strong) UIImage* bgImage;

@end

@implementation SLEditProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [SLColorManager primaryBackgroundColor];
    self.avatarOrBg = -1;
    [self setupUI];
}

#pragma mark - Methods
- (void)setupUI {
    [self.view addSubview:self.leftBackButton];
    [self.leftBackButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(self.view).offset(12);
        make.width.mas_equalTo(80);
    }];
    
    [self.view addSubview:self.saveBackButton];
    [self.saveBackButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).offset(-16);
        make.top.equalTo(self.view).offset(12);
        make.width.mas_equalTo(80);
    }];
    
    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.leftBackButton.mas_right);
        make.right.equalTo(self.saveBackButton.mas_left);
        make.centerY.equalTo(self.leftBackButton);
    }];
    
    [self.view addSubview:self.headerImageView];
    [self.headerImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.leftBackButton.mas_bottom).offset(16);
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(150);
    }];
    
    [self.view addSubview:self.avatarImageView];
    [self.avatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerImageView.mas_bottom).offset(-40);
        make.left.equalTo(self.view).offset(16);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];
    
    [self.view addSubview:self.addAvatarImageView];
    [self.addAvatarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.avatarImageView);
        make.size.mas_equalTo(CGSizeMake(50, 50));
    }];
    
    CGSize size = [self.nameLabel sizeThatFits:CGSizeZero];
    [self.view addSubview:self.nameLabel];
    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(self.avatarImageView.mas_bottom).offset(50);
        make.size.mas_equalTo(size);
    }];
    
    [self.view addSubview:self.nameTextField];
    [self.nameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.nameLabel);
        make.left.equalTo(self.nameLabel.mas_right).offset(8);
        make.right.equalTo(self.view).offset(-16);
    }];
    
    [self.view addSubview:self.briefLabel];
    [self.briefLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(16);
        make.top.equalTo(self.nameTextField.mas_bottom).offset(30);
        make.size.mas_equalTo(size);
    }];
    
    [self.view addSubview:self.briefTextView];
    [self.briefTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.briefLabel).offset(-8);
        make.left.equalTo(self.briefLabel.mas_right).offset(8);
        make.right.equalTo(self.view).offset(-16);
        make.height.mas_equalTo(200);
    }];
}

- (void)setEntity:(SLProfileEntity *)entity {
    _entity = entity;
    
    if (entity.bgImage) {
        [self.headerImageView sd_setImageWithURL:[NSURL URLWithString:entity.bgImage]];
    }
    if (entity.avatar) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:entity.avatar]];
    }
    self.nameTextField.text = entity.userName;
    self.briefTextView.text = entity.desc;
}

- (void)showActionSheet {
    // 创建 Action Sheet
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                         message:nil
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 打开相册的选项
    UIAlertAction *photoLibraryAction = [UIAlertAction actionWithTitle:@"Photo Library"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
        [self openPhotoLibrary];
    }];
    [photoLibraryAction setValue:[UIImage systemImageNamed:@"photo"] forKey:@"image"];
    
    // 拍照的选项
    UIAlertAction *takePhotoAction = [UIAlertAction actionWithTitle:@"Take Photo"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
        [self takePhoto];
    }];
    [takePhotoAction setValue:[UIImage systemImageNamed:@"camera"] forKey:@"image"];
    
    // 取消选项
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    // 添加动作到 Action Sheet
    [actionSheet addAction:photoLibraryAction];
    [actionSheet addAction:takePhotoAction];
    [actionSheet addAction:cancelAction];
    
    // 显示 Action Sheet
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - Actions
- (void)backPage {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveInfo {
    [SVProgressHUD show];
    @weakobj(self)
    NSData* avatar = nil;
    NSData* bg = nil;
    if (self.avatarImage) {
        avatar = UIImageJPEGRepresentation(self.avatarImage, 0.6);
    }
    if (self.bgImage) {
        bg = UIImageJPEGRepresentation(self.bgImage, 0.6);
    }
    [self.viewModel updateProfileWithUserID:self.entity.userId nickName:self.nameTextField.text desc:self.briefTextView.text avatar:avatar bg:bg resultHandler:^(BOOL isSuccess, NSError * _Nonnull error) {
        [SVProgressHUD dismiss];
        if (isSuccess) {
            @strongobj(self)
            if (self.updateSucessCallback) {
                self.updateSucessCallback();
            }
            [self dismissViewControllerAnimated:true completion:nil];
        }
    }];
}

- (void)chageBgImage {
    self.avatarOrBg = 0;
    [self showActionSheet];
}

- (void)chageAvatarImage {
    self.avatarOrBg = 1;
    [self showActionSheet];
}

#pragma mark - 打开相册
- (void)openPhotoLibrary {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.delegate = self;
        imagePicker.allowsEditing = YES; // 是否允许编辑
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        NSLog(@"Photo Library not available.");
    }
}

#pragma mark - 拍照
- (void)takePhoto {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.delegate = self;
        imagePicker.allowsEditing = YES; // 是否允许编辑
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        NSLog(@"Camera not available.");
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage]; // 获取编辑后的图片
    if (!selectedImage) {
        selectedImage = info[UIImagePickerControllerOriginalImage]; // 获取原始图片
    }
    if (self.avatarOrBg == 0) {
        self.headerImageView.image = selectedImage;
        self.bgImage = selectedImage;
    } else if (self.avatarOrBg == 1) {
        self.avatarImageView.image = selectedImage;
        self.avatarImage = selectedImage;
    }
    // 在此处理选中的图片
    NSLog(@"Selected image: %@", selectedImage);
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UI Elements
- (UIButton *)leftBackButton {
    if (!_leftBackButton) {
        _leftBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftBackButton setTitle:@"取消" forState:UIControlStateNormal];
        [_leftBackButton setTitleColor:[SLColorManager categoryNormalTextColor] forState:UIControlStateNormal];
        _leftBackButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        [_leftBackButton addTarget:self action:@selector(backPage) forControlEvents:UIControlEventTouchUpInside];
    }
    return _leftBackButton;
}

- (UIButton *)saveBackButton {
    if (!_saveBackButton) {
        _saveBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_saveBackButton setTitle:@"保存" forState:UIControlStateNormal];
        [_saveBackButton setTitleColor:[SLColorManager cellTitleColor] forState:UIControlStateNormal];
        _saveBackButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        [_saveBackButton addTarget:self action:@selector(saveInfo) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBackButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"编辑个人资料";
        _titleLabel.textColor = [SLColorManager cellTitleColor];
        _titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[UIImageView alloc] init];
        _headerImageView.backgroundColor = UIColor.lightGrayColor;
        _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headerImageView.clipsToBounds = YES;
        [_headerImageView setUserInteractionEnabled: YES];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chageBgImage)];
        [_headerImageView addGestureRecognizer:tap];
    }
    return _headerImageView;
}

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.backgroundColor = UIColor.lightGrayColor;
        _avatarImageView.layer.cornerRadius = 40;
        _avatarImageView.layer.masksToBounds = YES;
        _avatarImageView.layer.borderColor = [SLColorManager headerBorderColor].CGColor;
        _avatarImageView.layer.borderWidth = 2;
        
        [_avatarImageView setUserInteractionEnabled: YES];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chageAvatarImage)];
        [_avatarImageView addGestureRecognizer:tap];
    }
    return _avatarImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.text = @"姓名";
        _nameLabel.textColor = [SLColorManager cellTitleColor];
        _nameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _nameLabel;
}

- (UITextField *)nameTextField {
    if (!_nameTextField) {
        _nameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
        _nameTextField.borderStyle = UITextBorderStyleNone;
        _nameTextField.placeholder = @"请输入您的姓名";
        _nameTextField.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
        _nameTextField.textColor = [SLColorManager cellTitleColor];
        _nameTextField.keyboardType = UIKeyboardTypeDefault;
        _nameTextField.returnKeyType = UIReturnKeyDone;
        _nameTextField.delegate = self;
    }
    return _nameTextField;
}

- (UILabel *)briefLabel {
    if (!_briefLabel) {
        _briefLabel = [[UILabel alloc] init];
        _briefLabel.text = @"简介";
        _briefLabel.textColor = [SLColorManager cellTitleColor];
        _briefLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        _briefLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _briefLabel;
}

- (UITextView *)briefTextView {
    if (!_briefTextView) {
        _briefTextView = [[UITextView alloc] initWithFrame:CGRectZero];
        _briefTextView.font = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
        _briefTextView.textColor = [SLColorManager cellTitleColor];
        _briefTextView.keyboardType = UIKeyboardTypeDefault;
        _briefTextView.returnKeyType = UIReturnKeyDefault;
    }
    return _briefTextView;
}

- (UIImageView *)addAvatarImageView {
    if (!_addAvatarImageView) {
        _addAvatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"add_image_icon"]];
        _addAvatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_addAvatarImageView setUserInteractionEnabled: YES];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(chageAvatarImage)];
        [_addAvatarImageView addGestureRecognizer:tap];
    }
    return _addAvatarImageView;
}

- (SLProfilePageViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[SLProfilePageViewModel alloc] init];
    }
    return _viewModel;
}

@end
