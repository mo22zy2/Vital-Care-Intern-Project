(function () {
  var sidebar = document.getElementById('sidebar');
  var overlay = document.getElementById('sidebarOverlay');
  var toggle = document.getElementById('mobileToggle');

  if (toggle && sidebar && overlay) {
    function open() {
      sidebar.classList.add('open');
      overlay.classList.add('show');
    }

    function close() {
      sidebar.classList.remove('open');
      overlay.classList.remove('show');
    }

    toggle.addEventListener('click', function (e) {
      e.stopPropagation();
      if (sidebar.classList.contains('open')) {
        close();
      } else {
        open();
      }
    });

    overlay.addEventListener('click', close);

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && sidebar.classList.contains('open')) {
        close();
      }
    });
  }

  var searchInput = document.getElementById('globalSearch');
  if (searchInput) {
    searchInput.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') {
        var q = searchInput.value.trim();
        if (q) {
          window.location.href = '/search/?q=' + encodeURIComponent(q);
        }
      }
    });
  }
})();
