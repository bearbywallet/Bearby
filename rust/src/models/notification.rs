use zilpay::settings::notifications::NotificationState;

#[derive(Debug)]
pub struct BackgroundNotificationState {
    pub transactions: bool,
    pub price: bool,
    pub security: bool,
    pub balance: bool,
}

impl From<&NotificationState> for BackgroundNotificationState {
    fn from(notify: &NotificationState) -> Self {
        BackgroundNotificationState {
            transactions: notify.transactions,
            price: notify.price,
            security: notify.security,
            balance: notify.balance,
        }
    }
}

impl From<NotificationState> for BackgroundNotificationState {
    fn from(state: NotificationState) -> Self {
        BackgroundNotificationState {
            transactions: state.transactions,
            price: state.price,
            security: state.security,
            balance: state.balance,
        }
    }
}
