export function execFn<T extends (...args: any) => any>(fn: T | undefined | null, ...args: Parameters<T>) {
  return (isFunction(fn)
    ? fn(...(args as any))
    : undefined) as ReturnType<T>
}

export function isFunction(value: any): value is (...args: any[]) => any {
  return typeof value === 'function'
}

export function isNullable(value: any): value is null | undefined {
  return value === null || value === undefined
}
