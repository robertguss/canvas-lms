import type {ReactElement} from 'react'

export function App(): ReactElement {
  return (
    <main aria-labelledby="app-title">
      <section>
        <p>WTS LMS</p>
        <h1 id="app-title">Coursework workspace</h1>
        <p>React SPA scaffold consuming the Phoenix REST API.</p>
      </section>
    </main>
  )
}
