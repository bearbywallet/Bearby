/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import {
  StyleSheet
} from 'react-native';
import {
  PanGestureHandler,
  State as GestureState,
} from 'react-native-gesture-handler';
import Animated from 'react-native-reanimated';
const {
  event,
  cond,
  Value,
  block,
  set,
  eq,
  not,
  clockRunning,
  and,
  startClock,
  stopClock,
  spring,
  lessThan,
  call,
  Clock
} = Animated;

interface AnimatedEvent {
  state: number;
  translationX: number;
}

type Prop = {
  swipeThreshold: number;
  index: number;
  onSwipe: (index: number) => void;
};

export const SwipeRow: React.FC<Prop> = ({
  swipeThreshold,
  children,
  index,
  onSwipe
}) => {
  const clock = new Clock();
  const gestureState = new Value(GestureState.UNDETERMINED);
  const animState = {
    finished: new Value(0),
    position: new Value(0),
    velocity: new Value(0),
    time: new Value(0),
  };
  /**
   * Spring animation config Determines
   * how "springy" row is when it snaps
   * back into place after released.
   */
  const animConfig = {
    toValue: new Value(0),
    damping: 20,
    mass: 0.2,
    stiffness: 100,
    overshootClamping: false,
    restSpeedThreshold: 0.2,
    restDisplacementThreshold: 0.2,
  };
  /**
   * Called whenever gesture state changes.
   * (User begins/ends pan, or if the gesture is
   * cancelled/fails for some reason)
   */
  const onHandlerStateChange = event([
    {
      nativeEvent: (e: AnimatedEvent) =>
        block([
          // Update our animated value that tracks gesture state
          set(gestureState, e.state),
          // Spring row back into place when user lifts their finger before reaching threshold
          cond(
            and(eq(e.state, GestureState.END), not(clockRunning(clock))),
            startClock(clock)
          ),
        ]),
    },
  ]);
  const onPanEvent = event([
    {
      nativeEvent: (e: AnimatedEvent) =>
        block([
          cond(eq(gestureState, GestureState.ACTIVE), [
            // Update our translate animated value as the user pans
            set(animState.position, e.translationX),
            // If swipe distance exceeds threshold, delete item
            cond(
              lessThan(e.translationX, swipeThreshold),
              call([animState.position], () =>
                onSwipe(index)
              )
            ),
          ]),
        ]),
    },
  ]);

  return (
    <PanGestureHandler
      minDeltaX={10}
      onGestureEvent={onPanEvent}
      onHandlerStateChange={onHandlerStateChange}
    >
      <Animated.View
        style={{
          flex: 1,
          transform: [{ translateX: animState.position }],
        }}>
        <Animated.Code>
          {() =>
            block([
              // If the clock is running, increment position in next tick by calling spring()
              cond(clockRunning(clock), [
                spring(clock, animState, animConfig),
                // Stop and reset clock when spring is complete
                cond(animState.finished, [
                  stopClock(clock),
                  set(animState.finished, 0),
                ]),
              ]),
            ])
          }
        </Animated.Code>
        {children}
      </Animated.View>
    </PanGestureHandler>
  );
};

const styles = StyleSheet.create({
});
