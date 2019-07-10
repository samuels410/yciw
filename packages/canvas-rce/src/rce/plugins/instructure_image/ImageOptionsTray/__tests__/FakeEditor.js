/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

export default class FakeEditor {
  constructor() {
    this._$container = null

    this._selectedNode = null

    this.selection = {
      getNode: () => this._selectedNode,

      getContent: () => (this._selectedNode ? this._selectedNode.outerHTML : ''),

      setContent: contentString => {
        if (this._selectedNode) {
          this._selectedNode.remove()
        }
        const $temp = document.createElement('div')
        $temp.innerHTML = contentString
        this._selectedNode = this.$container.appendChild($temp.firstChild)
      }
    }
  }

  get $container() {
    return this._$container
  }

  initialize() {
    this.uninitialize()
    this._$container = document.body.appendChild(document.createElement('div'))
    this._$container.tabIndex = '0'
  }

  uninitialize() {
    if (this._$container) {
      this._$container.remove()
      this._$container = null
    }
  }

  appendElement($element) {
    this._$container.appendChild($element)
  }

  setSelectedNode($element) {
    this._selectedNode = $element
  }

  focus() {
    this._$container.focus()
  }
}
