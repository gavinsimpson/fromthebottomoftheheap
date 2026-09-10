(() => {
  const taxonomy = document.querySelector(".post-taxonomy");
  const metadata = document.querySelector(".quarto-title-meta");

  if (taxonomy && metadata) {
    taxonomy.prepend(metadata);
  }
})();
