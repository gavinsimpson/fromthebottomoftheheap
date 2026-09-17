(() => {
  const moveModalToBody = (modal) => {
    if (modal instanceof HTMLElement && modal.parentElement !== document.body) {
      document.body.append(modal);
    }
  };

  // Bootstrap recommends placing modals at the top level because fixed
  // positioning and z-indexes can be affected by an ancestor's stacking
  // context. Quarto layouts can create exactly that kind of ancestor.
  document.querySelectorAll(".modal").forEach(moveModalToBody);

  // Also cover modals introduced after the initial page load.
  document.addEventListener("show.bs.modal", (event) => {
    moveModalToBody(event.target);
  });
})();
