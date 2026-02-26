document.addEventListener("click", function(event) {
  const button = event.target.closest("[data-action='toggle-workout']");
  if (!button) return;

  const card = button.closest(".workout-log-card");
  if (!card) return;

  const body = card.querySelector(".workout-log-card__body");
  if (!body) return;

  const isCollapsed = body.classList.contains("workout-log-card__body--collapsed");

  if (isCollapsed) {
    body.classList.remove("workout-log-card__body--collapsed");
    button.textContent = "View less";
  } else {
    body.classList.add("workout-log-card__body--collapsed");
    button.textContent = "View more";
    card.scrollIntoView({ behavior: "smooth", block: "start" });
  }
});
