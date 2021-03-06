//
//  ViewController.m
//  chatInputBar
//
//  Created by li’s Air on 2018/6/15.
//  Copyright © 2018年 li’s Air. All rights reserved.
/*
 输入框高度自适应方案
    1、控制器里设置高度 JSQ master 分支有bug
    2、自定义textView,在内部控制，JSQ dev 分支，没什么bug
*/

#import "ViewController.h"
#import "JLTextContentView.h"


#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height


@interface ViewController ()<JLTextContentViewDatasource, UITextPasteDelegate>

@property (strong, nonatomic) UIView *inputBar;
@property (strong, nonatomic) NSLayoutConstraint *consInputBarBottom;
@property (strong, nonatomic) JLTextContentView *textContentView;

@property (assign, nonatomic) BOOL isAddKVO;
@property (assign, nonatomic) CGFloat heightSystemKeyboard;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self.view addSubview:self.inputBar];
    
    __weak typeof(self) ws = self;
    self.textContentView.textView.heightChangeBlock = ^{
        [ws.view layoutIfNeeded];
    };
    
    if (@available(iOS 11, *)) {
        self.textContentView.textView.pasteDelegate = self;
    }
    
    [self addConstraints];
    [self addNotification:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.textContentView.textView becomeFirstResponder];
}

- (void)dealloc {
    [self addNotification:NO];
}

#pragma -mark event response

- (void)keyboardWillChangeFrameNotification:(NSNotification *)notification {
    if ( !self.textContentView.textView.isFirstResponder )  return;
    
    CGRect endRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat offY = SCREEN_HEIGHT - endRect.origin.y;
    if (@available(iOS 11.0, *)) {
        offY = MAX(offY, self.view.safeAreaInsets.bottom);
    }
    if (self.heightSystemKeyboard == offY)
        return;
    
    self.heightSystemKeyboard = offY;
    
    NSTimeInterval duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    CGFloat animationCurveOption = (animationCurve << 16);
    
    self.consInputBarBottom.constant = -offY;
    [UIView animateWithDuration:duration delay:0 options:animationCurveOption animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

#pragma -mark JLInputViewDelegate

/**
 输入框字体，默认 18
 */
- (UIFont *)textFontOfTextContentView {
    return [UIFont systemFontOfSize:16];
}

/**
 无文本状态下输入框的高度，默认 50
 */
- (NSUInteger)preferredHeightOfTextContentView {
    return 32;
}
/**
 输入框最多显示行数，默认 4
 */
- (NSUInteger)maximumLineOfTextContentView {
    return 4;
}

#pragma -mark UITextPasteDelegate

/*
 fix issue #1 :https://github.com/jalyResource/GrowTextView/issues/1
 reference : https://stackoverflow.com/questions/51770900/uitextview-stange-animation-glitch-on-paste-action-ios11
 */
/* By default, the standard text controls will animate pasting or dropping text.
 * If you don't want this to happen for a certain paste or range, you can implement
 * this method and return false here.
 *
 * If you don't implement this, the default is true.
 */
- (BOOL)textPasteConfigurationSupporting:(id<UITextPasteConfigurationSupporting>)textPasteConfigurationSupporting shouldAnimatePasteOfAttributedString:(NSAttributedString*)attributedString toRange:(UITextRange*)textRange  API_AVAILABLE(ios(11.0)){
    return NO;
}

#pragma -mark override

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    NSLog(@"contentSize:%@", NSStringFromCGSize(self.textContentView.textView.contentSize));
}


#pragma -mark private

- (void)addConstraints {
    self.textContentView.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *txvSuper = self.textContentView.superview;
    
    [NSLayoutConstraint constraintWithItem:self.textContentView // left equal
                                 attribute:NSLayoutAttributeLeft
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:txvSuper
                                 attribute:NSLayoutAttributeLeft
                                multiplier:1
                                  constant:10].active = YES;
    [NSLayoutConstraint constraintWithItem:self.textContentView // right equal
                                 attribute:NSLayoutAttributeRight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:txvSuper
                                 attribute:NSLayoutAttributeRight
                                multiplier:1
                                  constant:-10].active = YES;
    [NSLayoutConstraint constraintWithItem:self.textContentView // bottom
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:txvSuper
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1
                                  constant:-8].active = YES;
    [NSLayoutConstraint constraintWithItem:self.textContentView // top
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:txvSuper
                                 attribute:NSLayoutAttributeTop
                                multiplier:1
                                  constant:8].active = YES;
    
    
    self.inputBar.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint constraintWithItem:self.inputBar          // inputBar left
                                 attribute:NSLayoutAttributeLeft
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.inputBar.superview
                                 attribute:NSLayoutAttributeLeft
                                multiplier:1
                                  constant:0].active = YES;
    [NSLayoutConstraint constraintWithItem:self.inputBar          // inputBar right
                                 attribute:NSLayoutAttributeRight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self.inputBar.superview
                                 attribute:NSLayoutAttributeRight
                                multiplier:1
                                  constant:0].active = YES;
    self.consInputBarBottom = [NSLayoutConstraint constraintWithItem:self.inputBar // inputBar bottom
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.inputBar.superview
                                                           attribute:NSLayoutAttributeBottom
                                                          multiplier:1
                                                            constant:0];
    self.consInputBarBottom.active = YES;
}

- (void)addNotification:(BOOL)isAdd {
    if (isAdd) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    }
}

#pragma mark - getter

- (UIView *)inputBar {
    if (!_inputBar) {
        _inputBar = [[UIView alloc] init];
        _inputBar.backgroundColor = [UIColor lightGrayColor];
        
        _textContentView = [JLTextContentView inputWiewWithDatasource:self];
        [_inputBar addSubview:_textContentView];
    }
    return _inputBar;
}


@end
