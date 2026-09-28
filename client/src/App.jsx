import "./style.css";

export default function App() {
  return (
    <main className="page-shell">
      <div className="grain" aria-hidden="true" />
      <header className="topbar">
        <a className="wordmark" href="#home" aria-label="MyManager home">
          <span className="mark" aria-hidden="true"><i /><i /><i /></span>
          <span>my<span className="wordmark-accent">manager</span></span>
        </a>
        <span className="status"><span className="status-dot" /> IN THE WORKS</span>
      </header>

      <section className="hero" id="home" aria-labelledby="headline">
        <div className="hero-copy">
          <p className="eyebrow"><span>01</span><span className="eyebrow-rule" /> A clearer way to work</p>
          <h1 id="headline">Good work<br />is <span className="headline-highlight">coming</span><span className="period">.</span></h1>
          <p className="intro">Your projects, your priorities, your next big idea.<br className="desktop-break" /> MyManager is getting ready to bring it all together.</p>
          <div className="arrival"><span className="arrival-mark">↗</span><span>Something useful is on its way.</span></div>
        </div>

        <div className="illustration" aria-label="Abstract project planning board illustration" role="img">
          <div className="orbit orbit-one" />
          <div className="orbit orbit-two" />
          <div className="sun-disc" />
          <div className="board">
            <div className="board-top"><span>THE NEXT THING</span><span className="board-menu">···</span></div>
            <div className="board-title">Make room<br />for better work.</div>
            <div className="board-progress"><span /><span /><span /></div>
            <div className="board-footer"><span>PLAN</span><span>FOCUS</span><span>FINISH</span></div>
          </div>
          <div className="note note-left"><span className="note-star">✳</span><span>One thing<br />at a time</span></div>
          <div className="note note-right"><span className="note-check">✓</span><span>Good things<br />in motion</span></div>
          <div className="spark spark-one">✳</div>
          <div className="spark spark-two">+</div>
          <span className="circle-label">MADE FOR<br />WHAT'S NEXT</span>
        </div>
      </section>

      <footer className="footer">
        <span className="footer-note">Thoughtfully building what comes next.</span>
        <span className="credit">A PRODUCT BY <strong>KRD LABS</strong></span>
      </footer>
    </main>
  );
}