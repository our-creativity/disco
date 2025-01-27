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
      sidebar: [
        {
          label: 'Overview',
          link: '',
        },
        {
          label: 'Core',
          items: [
            'core/providers',
            'core/scoped-di',
            'core/modals',
            'core/testing',
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
      ],
    }),
  ],
});
