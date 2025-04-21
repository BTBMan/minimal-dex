import antfu from '@antfu/eslint-config'
import { FlatCompat } from '@eslint/eslintrc'

const compat = new FlatCompat()

export default antfu(
  {
    react: true,
    ignores: ['src/components/ui', 'src/contract-data', 'contract'],
  },
  {
    rules: {
      'node/prefer-global/process': 'off',
      'style/jsx-one-expression-per-line': 'off',
      'react-dom/no-missing-button-type': 'off',
      '@next/next/no-img-element': 'off',
      'style/jsx-self-closing-comp': 'warn',
      'unused-imports/no-unused-vars': ['warn', { caughtErrors: 'none', argsIgnorePattern: '^_' }],
      'style/jsx-curly-spacing': ['error', { when: 'never', children: { when: 'never' } }],
      'perfectionist/sort-imports': ['error', {
        internalPattern: ['^~/.+', '^@/.+'],
        groups: [
          'type',
          ['parent-type', 'sibling-type', 'index-type', 'internal-type'],
          'builtin',
          'external',
          'internal',
          ['parent', 'sibling', 'index'],
          'side-effect',
          'object',
          'unknown',
        ],
        newlinesBetween: 'ignore',
        order: 'asc',
        type: 'natural',
      }],
      'react-hooks-extra/no-direct-set-state-in-use-effect': 'off',
      'react-hooks-extra/no-direct-set-state-in-use-layout-effect': 'off',
    },
  },
).prepend(
  compat.config({
    extends: 'plugin:@next/next/core-web-vitals',
  }),
)
