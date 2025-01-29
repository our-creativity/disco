// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
  site: 'https://disco.mariuti.com',
  integrations: [
    starlight({
      title: 'Disco',
      editLink: {
        baseUrl: 'https://github.com/our-creativity/disco/edit/main/docs/',
      },
      social: {
        github: 'https://github.com/our-creativity/disco',
      },
      head: [{
        tag: 'meta',
        attrs: {
          property: 'og:image',
          content: 'https://disco.mariuti.com/disco.png',
        }
      }],
      sidebar: [
        {
          label: '',
          link: 'https://pub.dev/packages/disco',
          badge: { text: 'pub.dev', variant: 'tip' },
          attrs: { target: '_blank', rel: 'noopener noreferrer' },
        },
        {
          label: 'Overview',
          link: '',
        },
        {
          label: 'Installing',
          link: 'installing',
        },
        {
          label: 'Core',
          items: [
            'core/providers',
            'core/scoped-di',
            'core/immutability',
            'core/modals',
            'core/testing',
            'core/provider-retrieval-process',
            'core/configuration',
          ],
        },
        {
          label: 'Miscellaneous',
          items: [
            'miscellaneous/reactivity',
            'miscellaneous/comparison-with-alternatives',
          ],
        },
        {
          label: 'Examples',
          items: [
            'examples/basic',
            'examples/solidart',
            'examples/preferences',
            'examples/bloc',
            'examples/auto-route',
          ],
        },
        {
          label: 'Authors',
          link: 'authors',
        },
      ],
    }),
  ],
});
