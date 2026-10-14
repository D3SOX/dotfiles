/* global __DEVIBE_COPY__ */
// Temporary copy review UI. Remove after choices are applied.
(() => {
  const copy = window.__DEVIBE_COPY__;
  if (!copy || typeof copy !== 'object') throw new Error('Missing window.__DEVIBE_COPY__ configuration.');

  const entries = Object.entries(copy);
  for (const [key, value] of entries) {
    if (!Array.isArray(value.options) || value.options.length < 5 || value.options.length > 10) {
      throw new Error(`Copy block “${key}” must have 5–10 options.`);
    }
  }

  const selections = Object.fromEntries(entries.map(([key]) => [key, 0]));
  let activeElement = null;

  const popover = document.createElement('aside');
  popover.className = 'devibe-panel devibe-popover';
  popover.hidden = true;
  popover.innerHTML = `
    <div class="devibe-handle">
      <strong></strong>
      <button class="devibe-close" type="button" aria-label="Close copy options">×</button>
    </div>
    <ol class="devibe-options"></ol>
  `;

  const output = document.createElement('aside');
  output.className = 'devibe-panel devibe-output';
  output.innerHTML = `
    <div class="devibe-handle"><strong>Copy choices</strong><span>drag to move</span></div>
    <div class="devibe-output-body">
      <textarea readonly aria-label="Selected copy codes"></textarea>
      <div class="devibe-output-actions">
        <span>Click outlined text to compare alternatives.</span>
        <button class="devibe-copy" type="button">Copy</button>
      </div>
    </div>
  `;

  document.body.append(popover, output);
  const textarea = output.querySelector('textarea');
  const copyButton = output.querySelector('.devibe-copy');
  const optionsList = popover.querySelector('.devibe-options');
  const popoverTitle = popover.querySelector('strong');

  function labelFor(key) {
    return copy[key].label || key.replaceAll('-', ' ').replace(/^./, (letter) => letter.toUpperCase());
  }

  function plainText(html) {
    const template = document.createElement('template');
    template.innerHTML = html.replaceAll('<br>', ' / ').replaceAll('<br />', ' / ');
    return template.content.textContent.trim().replace(/\s+/g, ' ');
  }

  function updateOutput() {
    textarea.value = entries
      .map(([key, value]) => {
        const choice = selections[key];
        return `${key}: ${String.fromCharCode(65 + choice)} — ${plainText(value.options[choice])}`;
      })
      .join('\n');
  }

  function clamp(value, min, max) {
    return Math.min(Math.max(value, min), Math.max(min, max));
  }

  function placePopover(target) {
    const gap = 10;
    const edge = 12;
    const targetRect = target.getBoundingClientRect();
    const panelRect = popover.getBoundingClientRect();
    const fitsRight = targetRect.right + gap + panelRect.width <= window.innerWidth - edge;
    const left = fitsRight ? targetRect.right + gap : targetRect.left - panelRect.width - gap;
    popover.style.left = `${clamp(left, edge, window.innerWidth - panelRect.width - edge)}px`;
    popover.style.top = `${clamp(targetRect.top, edge, window.innerHeight - panelRect.height - edge)}px`;
  }

  function selectOption(key, index) {
    selections[key] = index;
    activeElement.innerHTML = copy[key].options[index];
    optionsList.querySelectorAll('button').forEach((button, buttonIndex) => {
      button.setAttribute('aria-pressed', String(buttonIndex === index));
    });
    updateOutput();
  }

  function openPicker(target) {
    activeElement?.classList.remove('devibe-active');
    activeElement = target;
    activeElement.classList.add('devibe-active');
    const key = target.dataset.devibeKey;
    popoverTitle.textContent = labelFor(key);
    optionsList.replaceChildren(
      ...copy[key].options.map((option, index) => {
        const item = document.createElement('li');
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'devibe-option';
        button.setAttribute('aria-pressed', String(selections[key] === index));
        button.innerHTML = `<span class="devibe-letter">${String.fromCharCode(65 + index)}</span><span>${option}</span>`;
        button.addEventListener('click', () => selectOption(key, index));
        item.append(button);
        return item;
      }),
    );
    popover.hidden = false;
    placePopover(target);
  }

  function closePicker() {
    popover.hidden = true;
    activeElement?.classList.remove('devibe-active');
    activeElement = null;
  }

  function makeDraggable(panel) {
    const handle = panel.querySelector('.devibe-handle');
    handle.addEventListener('pointerdown', (event) => {
      if (event.target.closest('button')) return;
      event.preventDefault();
      const rect = panel.getBoundingClientRect();
      const offsetX = event.clientX - rect.left;
      const offsetY = event.clientY - rect.top;
      panel.style.right = 'auto';
      panel.style.bottom = 'auto';
      handle.setPointerCapture(event.pointerId);

      const move = (moveEvent) => {
        panel.style.left = `${clamp(moveEvent.clientX - offsetX, 8, window.innerWidth - rect.width - 8)}px`;
        panel.style.top = `${clamp(moveEvent.clientY - offsetY, 8, window.innerHeight - rect.height - 8)}px`;
      };
      const stop = () => {
        handle.removeEventListener('pointermove', move);
        handle.removeEventListener('pointerup', stop);
        handle.removeEventListener('pointercancel', stop);
      };
      handle.addEventListener('pointermove', move);
      handle.addEventListener('pointerup', stop);
      handle.addEventListener('pointercancel', stop);
    });
  }

  document.querySelectorAll('[data-devibe-key]').forEach((element) => {
    const key = element.dataset.devibeKey;
    if (!copy[key]) throw new Error(`No copy options configured for “${key}”.`);
    element.tabIndex = 0;
    element.setAttribute('role', 'button');
    element.setAttribute('aria-label', `Choose alternative copy for ${labelFor(key)}`);
    element.addEventListener('click', (event) => {
      event.preventDefault();
      event.stopPropagation();
      openPicker(element);
    });
    element.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        openPicker(element);
      }
    });
  });

  popover.querySelector('.devibe-close').addEventListener('click', closePicker);
  copyButton.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(textarea.value);
      copyButton.textContent = 'Copied';
    } catch {
      textarea.focus();
      textarea.select();
      copyButton.textContent = 'Press Ctrl/Cmd+C';
    }
    window.setTimeout(() => (copyButton.textContent = 'Copy'), 1500);
  });
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') closePicker();
  });
  window.addEventListener('resize', () => {
    if (!popover.hidden && activeElement) placePopover(activeElement);
  });

  makeDraggable(popover);
  makeDraggable(output);
  updateOutput();
})();
