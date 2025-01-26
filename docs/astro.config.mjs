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
          label: 'Introduction',
          autogenerate: { directory: 'introduction' },
        },
        {
          label: 'Core',
          autogenerate: { directory: 'core' },
        },
        {
          label: 'Miscellaneous',
          autogenerate: { directory: 'miscellaneous' },
        },
      ],
    }),
  ],
});
