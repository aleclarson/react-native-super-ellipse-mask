import * as React from 'react'
import { requireNativeComponent, ViewProps } from 'react-native'

const SuperEllipseMask = requireNativeComponent('SuperEllipseMask')

export const SuperEllipseMaskView = (props: ViewProps)=>
  <SuperEllipseMask {...props} />

SuperEllipseMaskView.displayName = 'SuperEllipseMaskView'
