/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import '@instructure/ui-themes/lib/canvas';
import generateId from 'format-message-generate-id/underscored_crc32';
import formatMessage from './src/format-message';
import translations from './src/i18n/indexLocales';

import Enzyme from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';

Enzyme.configure({
  disableLifecycleMethods: true,
  adapter: new Adapter()
});

formatMessage.setup({
  generateId,
  translations,
});

document.documentElement.setAttribute('dir', 'ltr');

// set up mocks for native APIs
if (!('MutationObserver' in window)) {
  Object.defineProperty(window, 'MutationObserver', { value: require('@sheerun/mutationobserver-shim') });
}
