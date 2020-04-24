import React, { Component, ReactNode } from 'react';
import { requireNativeComponent, ViewProps } from 'react-native';

const SuperEllipseMask = requireNativeComponent(
  'SuperEllipseMask',
);

export type SuperEllipseMaskViewProps = Props

type Props = ViewProps & {
  radius?: number | {
    topLeft?: number
    topRight?: number
    bottomRight?: number
    bottomLeft?: number
  }
  children?: ReactNode
}

export class SuperEllipseMaskView extends Component<Props> {
  render() {
    let { radius, ...rest } = this.props;

    if (typeof radius !== 'object') {
      radius = {
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      }
    }

    return <SuperEllipseMask {...rest} {...radius} />;
  }
}

export default SuperEllipseMaskView
