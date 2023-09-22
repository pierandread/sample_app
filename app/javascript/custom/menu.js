// menu manipulation

// add toggle listeners
function addToggleListener(selected_id, menu_id, toggle_class) {
  let selected_item = document.querySelector(`#${selected_id}`);
  selected_item.addEventListener("click", function (event) {
    event.preventDefault();
    let menu = document.querySelector(`#${menu_id}`);
    menu.classList.toggle(toggle_class);
  });
}

document.addEventListener("turbo:load", function () {
  addToggleListener("hamburger", "navbar-menu", "collapse");
  addToggleListener("account", "dropdown-menu", "active");
});
