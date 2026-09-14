(() => {
  const taxonomy = document.querySelector(".post-taxonomy");
  const metadata = document.querySelector(".quarto-title-meta");
  const support = document
    .querySelector(".post-links .buy-me-coffee")
    ?.closest("p");

  if (taxonomy && metadata) {
    taxonomy.prepend(metadata);
  }

  if (taxonomy && support) {
    support.classList.add("post-support");
    taxonomy.prepend(support);
  }
})();
