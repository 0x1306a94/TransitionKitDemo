//
//  ViewController.m
//  TransitionKitDemo
//
//  Created by king on 2022/7/15.
//

#import "ViewController.h"

@import TransitionKit;
@import MBProgressHUD;

static NSString *const KKPlaceOrderInitState = @"init";
static NSString *const KKPlaceOrderInState = @"in";
static NSString *const KKPlaceOrderLoadingState = @"loading";
static NSString *const KKPlaceOrderWaitLoadingState = @"wait-loading";
static NSString *const KKPlaceOrderCloseWaitLoadingState = @"close-wait-loading";
static NSString *const KKPlaceOrderSliderValidationState = @"slider-validation";
static NSString *const KKPlaceOrderOrderTokenState = @"order-token";
static NSString *const KKPlaceOrderSubmitState = @"submit";
static NSString *const KKPlaceOrderPollingState = @"polling";
static NSString *const KKPlaceOrderPollingResultState = @"polling-result";
static NSString *const KKPlaceOrderFetchPayParamsState = @"fetch-pay-params";
static NSString *const KKPlaceOrderPayState = @"pay";
static NSString *const KKPlaceOrderFinishState = @"finish";

static NSString *const KKPlaceOrderInitEvent = @"init-event";
static NSString *const KKPlaceOrderInEvent = @"in-event";
static NSString *const KKPlaceOrderLoadingEvent = @"loading-evenet";
static NSString *const KKPlaceOrderWaitLoadingEvent = @"wait-loading-evenet";
static NSString *const KKPlaceOrderCloseWaitLoadingEvent = @"wait-loading";
static NSString *const KKPlaceOrderSliderValidationEvent = @"slider-validation-evenet";
static NSString *const KKPlaceOrderOrderTokenEvent = @"order-token-evenet";
static NSString *const KKPlaceOrderSubmitEvent = @"submit-evenet";
static NSString *const KKPlaceOrderPollingEvent = @"polling-evenet";
static NSString *const KKPlaceOrderPollingResultEvent = @"polling-result-event";
static NSString *const KKPlaceOrderFetchPayParamsEvent = @"fetch-pay-params-evenet";
static NSString *const KKPlaceOrderPayEvent = @"pay-evenet";
static NSString *const KKPlaceOrderFinishEvent = @"finish-evenet";

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *sliderValidationSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *tokenValidationSwitch;

@property (nonatomic, strong) TKStateMachine *stateMachine;
@property (nonatomic, strong) MBProgressHUD *loadingHUD;
@property (nonatomic, strong) MBProgressHUD *waitHUD;
@property (nonatomic, assign) BOOL placeOrdering;
@property (nonatomic, assign) NSInteger pollCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.placeOrdering = NO;
    self.pollCount = 0;

    self.loadingHUD = [[MBProgressHUD alloc] initWithView:self.view];
    self.loadingHUD.userInteractionEnabled = NO;
    self.loadingHUD.mode = MBProgressHUDModeIndeterminate;
    self.loadingHUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.loadingHUD.bezelView.color = [UIColor redColor];
    self.loadingHUD.detailsLabel.text = @"loading...";

    self.waitHUD = [[MBProgressHUD alloc] initWithView:self.view];
    self.waitHUD.userInteractionEnabled = NO;
    self.waitHUD.mode = MBProgressHUDModeIndeterminate;
    self.waitHUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.waitHUD.bezelView.color = [UIColor orangeColor];
    self.waitHUD.detailsLabel.text = @"waitng...";

    [self.view addSubview:self.loadingHUD];
    [self.view addSubview:self.waitHUD];

    [self setupStateMachine];
}

- (IBAction)placeOrderAction:(UIButton *)sender {
    if (self.placeOrdering) {
        if (self.waitHUD.superview) {
            [self.stateMachine fireEvent:KKPlaceOrderCloseWaitLoadingEvent userInfo:nil error:nil];
        } else {
            [self.stateMachine fireEvent:KKPlaceOrderWaitLoadingEvent userInfo:nil error:nil];
        }

    } else {
        [self.stateMachine fireEvent:KKPlaceOrderInEvent userInfo:nil error:nil];
    }
}

- (void)setupStateMachine {
    TKStateMachine *stateMachine = [TKStateMachine new];
    self.stateMachine = stateMachine;

    __weak typeof(self) weakSelf = self;
    TKState *initState = [TKState stateWithName:KKPlaceOrderInitState];
    [initState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        weakSelf.placeOrdering = NO;
        weakSelf.pollCount = 1;
        NSLog(@"init");
    }];

    TKState *inState = [TKState stateWithName:KKPlaceOrderInState];
    [inState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"开始下单...");
        weakSelf.placeOrdering = YES;
        if (weakSelf.sliderValidationSwitch.on) {
            [weakSelf.stateMachine fireEvent:KKPlaceOrderSliderValidationEvent userInfo:nil error:nil];
        } else if (weakSelf.tokenValidationSwitch.on) {
            [weakSelf.stateMachine fireEvent:KKPlaceOrderOrderTokenEvent userInfo:nil error:nil];
        }
    }];

    TKState *loadingState = [TKState stateWithName:KKPlaceOrderLoadingState];
    [loadingState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"开启loading");
        [weakSelf.loadingHUD showAnimated:YES];
    }];

    [loadingState setDidExitStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"关闭loading");
        [weakSelf.loadingHUD hideAnimated:YES];
    }];

    TKState *waitLoadingState = [TKState stateWithName:KKPlaceOrderWaitLoadingState];
    [waitLoadingState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"开启轮询等待loading");
        [weakSelf.view addSubview:self.waitHUD];
        [weakSelf.waitHUD showAnimated:YES];
    }];

    TKState *closeWaitLoadingState = [TKState stateWithName:KKPlaceOrderCloseWaitLoadingState];
    [closeWaitLoadingState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"关闭轮询等待loading");
        [weakSelf.waitHUD hideAnimated:YES];
        [weakSelf.waitHUD removeFromSuperview];
    }];

    TKState *sliderValidationState = [TKState stateWithName:KKPlaceOrderSliderValidationState];
    [sliderValidationState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"开始滑块验证....");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"滑块验证成功");
            if (weakSelf.tokenValidationSwitch.on) {
                [weakSelf.stateMachine fireEvent:KKPlaceOrderOrderTokenEvent userInfo:nil error:nil];
            } else {
                [weakSelf.stateMachine fireEvent:KKPlaceOrderOrderTokenEvent userInfo:nil error:nil];
            }
        });
    }];

    TKState *orderTokenState = [TKState stateWithName:KKPlaceOrderOrderTokenState];
    [orderTokenState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"获取toke....");
        [weakSelf.stateMachine fireEvent:KKPlaceOrderLoadingEvent userInfo:nil error:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"获取toke成功");
            [weakSelf.stateMachine fireEvent:KKPlaceOrderSubmitEvent userInfo:nil error:nil];
        });
    }];

    TKState *submitState = [TKState stateWithName:KKPlaceOrderSubmitState];
    [submitState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"生成订单任务....");
        [weakSelf.stateMachine fireEvent:KKPlaceOrderLoadingEvent userInfo:nil error:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"生成订单成功");
            [weakSelf.stateMachine fireEvent:KKPlaceOrderPollingEvent userInfo:nil error:nil];
        });
    }];

    TKState *pollingState = [TKState stateWithName:KKPlaceOrderPollingState];
    [pollingState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"开始第%ld次轮询....", weakSelf.pollCount);
        if (weakSelf.pollCount == 1) {
            [weakSelf.stateMachine fireEvent:KKPlaceOrderWaitLoadingEvent userInfo:nil error:nil];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.pollCount++;
            [weakSelf.stateMachine fireEvent:KKPlaceOrderPollingResultEvent userInfo:nil error:nil];
        });
    }];

    TKState *pollingResultState = [TKState stateWithName:KKPlaceOrderPollingResultState];
    [pollingResultState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        if (weakSelf.pollCount > 5) {
            NSLog(@"轮询成功");
            [weakSelf.stateMachine fireEvent:KKPlaceOrderCloseWaitLoadingEvent userInfo:nil error:nil];
            [weakSelf.stateMachine fireEvent:KKPlaceOrderFetchPayParamsEvent userInfo:nil error:nil];
        } else {
            NSLog(@"轮询失败");
            [weakSelf.stateMachine fireEvent:KKPlaceOrderPollingEvent userInfo:nil error:nil];
        }
    }];

    TKState *fetchPayParamsState = [TKState stateWithName:KKPlaceOrderFetchPayParamsState];
    [fetchPayParamsState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"获取支付参数...");
        [weakSelf.stateMachine fireEvent:KKPlaceOrderLoadingEvent userInfo:nil error:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"获取支付参数成功");
            [weakSelf.stateMachine fireEvent:KKPlaceOrderPayEvent userInfo:nil error:nil];
        });
    }];

    TKState *payState = [TKState stateWithName:KKPlaceOrderPayState];
    [payState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        NSLog(@"发起支付...");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"支付完成");
            [weakSelf.stateMachine fireEvent:KKPlaceOrderFinishEvent userInfo:nil error:nil];
        });
    }];

    TKState *finishState = [TKState stateWithName:KKPlaceOrderFinishState];
    [finishState setDidEnterStateBlock:^(TKState *state, TKTransition *transition) {
        weakSelf.placeOrdering = NO;
        NSLog(@"下单完成");
        [weakSelf.stateMachine fireEvent:KKPlaceOrderInitEvent userInfo:nil error:nil];
    }];

    [stateMachine addStates:@[
        initState,
        inState,
        loadingState,
        waitLoadingState,
        closeWaitLoadingState,
        sliderValidationState,
        orderTokenState,
        submitState,
        pollingState,
        pollingResultState,
        fetchPayParamsState,
        payState,
        finishState,
    ]];
    stateMachine.initialState = initState;

    TKEvent *initEvent = [TKEvent eventWithName:KKPlaceOrderInitEvent transitioningFromStates:@[finishState] toState:initState];

    TKEvent *inEvent = [TKEvent eventWithName:KKPlaceOrderInEvent transitioningFromStates:@[initState] toState:inState];

    TKEvent *loadingEvent = [TKEvent eventWithName:KKPlaceOrderLoadingEvent transitioningFromStates:@[orderTokenState, submitState, fetchPayParamsState] toState:loadingState];

    TKEvent *sliderValidationEvent = [TKEvent eventWithName:KKPlaceOrderSliderValidationEvent transitioningFromStates:@[inState] toState:sliderValidationState];

    TKEvent *orderTokenEvent = [TKEvent eventWithName:KKPlaceOrderOrderTokenEvent transitioningFromStates:@[inState, sliderValidationState] toState:orderTokenState];

    TKEvent *submitEvent = [TKEvent eventWithName:KKPlaceOrderSubmitEvent transitioningFromStates:@[inState, sliderValidationState, orderTokenState, loadingState] toState:submitState];

    TKEvent *waitLoadingEvent = [TKEvent eventWithName:KKPlaceOrderWaitLoadingEvent transitioningFromStates:@[pollingState, pollingResultState, closeWaitLoadingState] toState:waitLoadingState];

    TKEvent *closeWaitLoadingEvent = [TKEvent eventWithName:KKPlaceOrderCloseWaitLoadingEvent transitioningFromStates:@[pollingState, pollingResultState, waitLoadingState] toState:closeWaitLoadingState];

    TKEvent *pollingEvent = [TKEvent eventWithName:KKPlaceOrderPollingEvent transitioningFromStates:@[submitState, loadingState, pollingResultState] toState:pollingState];

    TKEvent *pollingResultEvent = [TKEvent eventWithName:KKPlaceOrderPollingResultEvent transitioningFromStates:@[pollingState, waitLoadingState, closeWaitLoadingState] toState:pollingResultState];

    TKEvent *payParamsEvent = [TKEvent eventWithName:KKPlaceOrderFetchPayParamsEvent transitioningFromStates:@[pollingResultState, waitLoadingState, closeWaitLoadingState] toState:fetchPayParamsState];

    TKEvent *payEvent = [TKEvent eventWithName:KKPlaceOrderPayEvent transitioningFromStates:@[fetchPayParamsState, loadingState] toState:payState];

    TKEvent *finishEvent = [TKEvent eventWithName:KKPlaceOrderFinishEvent transitioningFromStates:@[payState, fetchPayParamsState] toState:finishState];

    [stateMachine addEvents:@[
        initEvent,
        inEvent,
        loadingEvent,
        sliderValidationEvent,
        orderTokenEvent,
        submitEvent,
        waitLoadingEvent,
        closeWaitLoadingEvent,
        pollingEvent,
        pollingResultEvent,
        payParamsEvent,
        payEvent,
        finishEvent,
    ]];

    [stateMachine activate];
}
@end

