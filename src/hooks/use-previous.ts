import type React from 'react'
import { useEffect, useRef } from 'react'

export default function usePrevious<T>(value: T | React.ComponentState) {
  const ref = useRef<T>(value)

  useEffect(() => {
    ref.current = value
  }, [value])

  return ref.current
};
