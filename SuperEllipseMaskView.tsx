import * as React from 'react'
import { requireNativeComponent, ViewProps, NativeMethodsMixin } from 'react-native'

const SuperEllipseMask = requireNativeComponent('SuperEllipseMask')

export const SuperEllipseMaskView = React.forwardRef(
  (props: ViewProps, ref: React.Ref<NativeMethodsMixin>) =>
    <SuperEllipseMask ref={ref} {...props} />
)

SuperEllipseMaskView.displayName = 'SuperEllipseMaskView'
