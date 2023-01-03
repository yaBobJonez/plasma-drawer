/***************************************************************************
 *   Copyright (C) 2014-2015 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.kicker 0.1 as Kicker

Item {
    id: kicker

    anchors.fill: parent

    signal reset

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    Plasmoid.compactRepresentation: null
    Plasmoid.fullRepresentation: compactRepresentation

    property Item dragSource: null

    property alias systemFavoritesModel: systemModel.favoritesModel

    function logModelChildren(model, leadingSpace=0) {
        let spacing = Array(leadingSpace + 1).join(" ");
        // console.log(model.description);
        // console.log(model.data(model.index(0, 0), 0));
        
        for (let i = 0; i < model.count; i++) {
            let hasChildren = model.data(model.index(i, 0), 0x0107);
            
            console.log(spacing + `${model.data(model.index(i, 0), 0)} - `
                            // + hasChildren ? `(${model.modelForRow(i).count}) - ` : ' - '
                            + `${model.data(model.index(i, 0), 0x0101)}, `
                            // + `Deco: ${model.data(model.index(0, 0), 1)}, `
                            // + `IsParent: ${model.data(model.index(i, 0), 0x0106)}, `
                            // + `HasChildren: ${hasChildren}, `
                            // + `Group: ${model.data(model.index(i, 0), 0x0102)}`
                        );
            
            if (hasChildren) {
                logModelChildren(model.modelForRow(i), leadingSpace + 2);
                continue;
            }
        }
    }

    function action_menuedit() {
        processRunner.runMenuEditor();
    }

    Component {
        id: compactRepresentation
        CompactRepresentation {}
    }

    Component {
        id: menuRepresentation
        MenuRepresentation {}
    }

    Connections {
        target: systemFavoritesModel

        function onCountChanged() {
            if (systemFavoritesModel.count == 0) {
                plasmoid.configuration.showSystemActions = false;
            }
        }

        function onFavoritesChanged() {
            plasmoid.configuration.favoriteSystemActions = target.favorites;
        }
    }

    Connections {
        target: plasmoid.configuration

        function onFavoriteSystemActionsChanged() {
            systemFavoritesModel.favorites = plasmoid.configuration.favoriteSystemActions;
        }

        function onHiddenApplicationsChanged() {
            // TODO: handle case when hiding applications nested in directories
            // Force refresh on hidden
            appsModel.refresh();
        }
    }

    Kicker.AppsModel {
        id: appsModel

        autoPopulate: true

        flat: false
        showTopLevelItems: true
        sorted: false
        showSeparators: false
        paginate: false

        appletInterface: plasmoid
        appNameFormat: plasmoid.configuration.appNameFormat

        Component.onCompleted: {
            appsModel.refresh();
        }
    }

    Kicker.SystemModel {
        id: systemModel

        onModelReset: {
            // Reassign favorites on every reset in case any of them have since become valid
            systemFavoritesModel.favorites = plasmoid.configuration.favoriteSystemActions;
        }

        Component.onCompleted: {
            systemFavoritesModel.enabled = true;
            systemFavoritesModel.maxFavorites = 8;
            // systemFavoritesModel.favorites = plasmoid.configuration.favoriteSystemActions;
            // systemModel.refresh();
        }
    }

    Kicker.RunnerModel {
        id: runnerModel
        // favoritesModel: globalFavorites
        runners: plasmoid.configuration.useExtraRunners ? new Array("services").concat(plasmoid.configuration.extraRunners) : "services"
        appletInterface: plasmoid
        deleteWhenEmpty: false
    }

    Kicker.DragHelper {
        id: dragHelper
    }

    Kicker.ProcessRunner {
        id: processRunner;
    }

    PlasmaCore.FrameSvgItem {
        id : highlightItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    PlasmaCore.FrameSvgItem {
        id : panelSvg

        visible: false

        imagePath: "widgets/panel-background"
    }

    PlasmaComponents.Label {
        id: toolTipDelegate

        width: contentWidth
        height: contentHeight

        property Item toolTip

        text: (toolTip != null) ? toolTip.text : ""
    }

    function resetDragSource() {
        dragSource = null;
    }

    Component.onCompleted: {
        plasmoid.setAction("menuedit", i18n("Edit Applications..."));
        // rootModel.refreshed.connect(reset);
        dragHelper.dropped.connect(resetDragSource);
    }
}
