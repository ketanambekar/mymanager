import React from "react";

const features = [
  {
    number: "01",
    title: "Bring your tasks together",
    description: "Capture what needs doing, break bigger tasks into subtasks, and see what is open, completed, or overdue.",
  },
  {
    number: "02",
    title: "Make repeat work easier",
    description: "Set up daily, weekly, monthly, yearly, or custom recurring tasks so regular work stays on your radar.",
  },
  {
    number: "03",
    title: "Give every project a place",
    description: "Organize tasks into projects and subprojects, and keep your priorities clear as your plans grow.",
  },
];

export default function LandingView() {
  return (
    <div className="landing" data-theme="light">
      <header className="landing-header">
        <a className="landing-brand" href="/" aria-label="MyManger home">
          <span aria-hidden="true" className="landing-brand-mark"><i /><i /><i /></span>
          <span>My<span>Manger</span></span>
        </a>
        <nav aria-label="Main navigation" className="landing-nav">
          <a className="landing-nav-features" href="#features">Features</a>
          <a className="landing-signin" href="/login">Sign in</a>
          <a className="landing-button landing-button-small" href="/login">Get started <span aria-hidden="true">↗</span></a>
        </nav>
      </header>

      <main>
        <section className="landing-hero">
          <div className="landing-hero-copy">
            <p className="landing-eyebrow"><span aria-hidden="true" /> A LITTLE MORE CLARITY, EVERY DAY</p>
            <h1>Make room for <em>better work.</em></h1>
            <p className="landing-intro">A clear, simple home for your tasks and projects. Plan your day, keep recurring work moving, and focus on what matters.</p>
            <div className="landing-actions">
              <a className="landing-button" href="/login">Get started with Google <span aria-hidden="true">↗</span></a>
              <a className="landing-text-link" href="#features">Explore features <span aria-hidden="true">↓</span></a>
            </div>
            <p className="landing-note">Your projects. Your pace. One clear workspace.</p>
          </div>

          <div className="landing-preview" aria-label="Illustration of a MyManger task workspace">
            <div className="landing-preview-top"><span><i /> MY WORKSPACE</span><span>YOUR DAY, IN FOCUS</span></div>
            <div className="landing-preview-body">
              <div className="landing-preview-heading"><div><small>MONDAY OVERVIEW</small><strong>A little progress<br />goes a long way.</strong></div><span>✳</span></div>
              <div className="landing-preview-list">
                <div><span className="landing-check done">✓</span><span>Plan the week ahead<small>PERSONAL</small></span><b>DONE</b></div>
                <div><span className="landing-check" /><span>Make progress on a project<small>WORK</small></span><b>TODAY</b></div>
                <div><span className="landing-check" /><span>Make time for a daily habit<small>ROUTINE · REPEATS</small></span><b>DAILY</b></div>
              </div>
              <div className="landing-preview-bottom"><span>ONE THING AT A TIME</span><span>✳</span></div>
            </div>
          </div>
        </section>

        <section className="landing-features" id="features" aria-labelledby="features-heading">
          <div className="landing-section-heading">
            <div><p className="landing-eyebrow">A WORKSPACE THAT WORKS WITH YOU</p><h2 id="features-heading">Less juggling.<br /><em>More doing.</em></h2></div>
            <p>From the small things to the big picture, keep your work organized in a way that feels manageable.</p>
          </div>
          <div className="landing-feature-grid">
            {features.map((feature) => (
              <article className="landing-feature" key={feature.number}>
                <span className="landing-feature-number">{feature.number} /</span>
                <h3>{feature.title}</h3>
                <p>{feature.description}</p>
              </article>
            ))}
          </div>
        </section>

        <section className="landing-cta" aria-labelledby="cta-heading">
          <div><p className="landing-eyebrow">READY WHEN YOU ARE</p><h2 id="cta-heading">A clearer day starts here.</h2><p>Bring your tasks and projects together in MyManger.</p></div>
          <a className="landing-button" href="/login">Get started <span aria-hidden="true">↗</span></a>
        </section>
      </main>
      <footer className="landing-footer"><span>MyManger</span><span className="landing-footer-credit">A product by <strong>KRD Labs</strong></span><a href="/login">Sign in ↗</a></footer>
    </div>
  );
}
