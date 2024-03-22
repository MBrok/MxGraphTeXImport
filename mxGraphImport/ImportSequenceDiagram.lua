function PrintDiagramStart(tex)
    tex.print("\\begin{figure}[ht]");
    tex.print("\\centering")
    tex.print("\\begin{tikzpicture}");
    
end

function PrintDiagramEnd(tex,caption)
    tex.print("\\end{tikzpicture}");
    tex.print("\\caption{"..caption.."}")
    tex.print("\\end{figure}")
end

function ReadDiagramFile(filename,handler,xml2lua)
    local file = io.open(filename, 'r')
    if file == nil then
        print("File "..filename.." not found.");
        os.exit(1);
    end
    local fileContent = file:read("*a")
    if xml2lua == nil then
        print("XML2Lua Library not present. You need to fetch it from https://github.com/manoelcampos/xml2lua");
        os.exit(1);
    end
    local parser = xml2lua.parser(handler)
    parser:parse(fileContent)
end

function InsertSequenceDiagram(tex,infilename)
    print("Importing sequence diagram from "..infilename);
    local xml2lua = require("xml2lua");
    local handler = require("xmlhandler.tree");
    handler = handler:new();
    ReadDiagramFile(infilename, handler, xml2lua);
    print("File " .. infilename .. " read.");

    local caption = handler.root.mxfile.diagram._attr.name;

    local diagramWidth = handler.root.mxfile.diagram.mxGraphModel._attr.dx;
    local diagramHeight = handler.root.mxfile.diagram.mxGraphModel._attr.dy;

    local printWidth = tex.dimen['textwidth'] / 65536;
    local printHeight = tex.dimen['textheight'] / 65536;

    local scaleX = printWidth / diagramWidth;
    local scaleY = printHeight / diagramHeight;

    local scale = math.min(scaleX, scaleY);
    local maxY = printHeight * scale;

    local firstDiagramRoot = handler.root.mxfile.diagram.mxGraphModel.root; ---lets assume there is only one for now
    local graph = ReadVertices(firstDiagramRoot, scale, maxY);
    LayoutEdges(graph.edges, graph.vertices);

    PrintDiagramStart(tex);
    PrintVertices(tex, graph.vertices);
    PrintEdges(tex, graph.edges);
    PrintDiagramEnd(tex,caption);
    handler = nil;
    xml2lua = nil;
end

local function getVertexById(id, vertices)
    for i, vertex in pairs(vertices) do
        if vertex.id == id then
            print("Vertex for ID "..id.." found!");
            return vertex;
        end
        if vertex.children then
            for j, childVertex in pairs(vertex.children) do
                if(childVertex.id == id) then
                    print("ChildVertex with ID "..id.." found!");
                    return childVertex;
                end
            end
        end
    end
    print("No Vertex for ID "..id.." found!!!!");
    return nil;
end

function LayoutEdges(edges, vertices)
    for e, edge in pairs(edges) do
        if edge.source and edge.target then
            local sourceVertex = getVertexById(edge.source, vertices);
            local targetVertex = getVertexById(edge.target, vertices);
            if (sourceVertex and targetVertex) then
                local isSourceRighttexTarget = sourceVertex.x < targetVertex.x;
                if isSourceRighttexTarget then
                    edge.sourceY = math.min(sourceVertex.y, targetVertex.y);
                    edge.targetY = edge.targetY;
                    edge.isRightToLeft = true;
                else
                    edge.sourceY = math.max(sourceVertex.y - sourceVertex.height, targetVertex.y - targetVertex.height);
                    edge.targetY = edge.sourceY;
                    edge.isRightToLeft = false;
                end
            end
        end
    end
end

function PrintEdges(tex, edges)
    tex.print("\\begin{pgfonlayer}{background}");
    for i, edge in pairs(edges) do
        if edge.source and edge.target then
            local edgeText = "";
            if edge.value and string.len(edge.value) > 0 then
                edgeText = "node[above, font=\\tiny] {" .. edge.value .. "} ";
            end

            local anchorSource = ".west";
            local anchorTarget = ".east";
            if edge.isRightToLeft then
                anchorSource = ".east";
                anchorTarget = ".west";
            end
            local edgeSource = edge.source .. anchorSource;
            local edgeTarget = edge.target .. anchorTarget;
            if edge.sourceY and edge.targetY then
                edgeTarget = edgeTarget .. "|-0pt, " .. edge.targetY .. "pt";
                edgeSource = edgeSource .. "|-0pt, " .. edge.sourceY .. "pt";
            elseif edge.sourceY then
                edgeTarget = edgeTarget .. "|-0pt, " .. edge.sourceY .. "pt";
                edgeSource = edgeSource .. "|-0pt, " .. edge.sourceY .. "pt";
            elseif edge.targetY then
                edgeSource = edgeSource .. "|-0pt, " .. edge.targetY .. "pt";
                edgeTarget = edgeTarget .. "|-0pt, " .. edge.targetY .. "pt";
            end
            tex.print("\\draw[->] (" .. edgeSource .. ") -- " .. edgeText .. " (" .. edgeTarget .. ");");
        end
    end
    tex.print("\\end{pgfonlayer}");
end

function PrintVertices(tex, vertices)
    for i, vertex in pairs(vertices) do
        if vertex.shouldPrint == false then
            goto continue;
        end
        local dimensions = "";
        if vertex.isSwimlane then
            dimensions = ",text width=" .. vertex.width .. "pt, align=left, below right=0pt, font=\\tiny, fill=lightgray";
        elseif vertex.width and vertex.height then
            dimensions = ",text width=" ..
            vertex.width ..
            "pt, minimum height=" .. vertex.height .. "pt, align=left, below right=0pt, font=\\tiny, fill=white";
        end

        tex.print("\\node [draw" ..
        dimensions .. "] (" .. vertex.id .. ") at (" .. vertex.x ..
        "pt," .. vertex.y .. "pt) {\\textbf{" .. vertex.value .. "}};");

        if vertex.isSwimlane then
            --draw swimlane 
            tex.print("\\begin{pgfonlayer}{background}");
            tex.print("\\draw[dash pattern=on 2pt off 4pt] ("..vertex.id..") -- ++(0,-"..vertex.y.."pt) -| ("..vertex.id..");");
            tex.print("\\end{pgfonlayer}");
        end

        if vertex.children then
            for j, partVertex in pairs(vertex.children) do
                local partDimensions = "";
                if partVertex.width and partVertex.height then
                    partDimensions = ", text width=" ..
                    partVertex.width ..
                    "pt, minimum width=" ..
                    partVertex.width ..
                    "pt, minimum height=" .. vertex.height .. "pt, align=left, below right, fill=white, font=\\tiny";
                end
                if not partVertex.value or string.len(partVertex.value) <= 0 then
                    tex.print("\\node [draw" ..
                    partDimensions .. "] (" .. partVertex.id .. ") at (" .. partVertex.x .. "pt," ..
                    partVertex.y .. "pt) {");
                    tex.print("};");
                else
                    tex.print("\\begin{pgfonlayer}{foreground}");
                    tex.print("\\node [draw" ..
                    partDimensions ..
                    "] (" .. partVertex.id .. ") at (" .. partVertex.x .. "pt," ..
                    partVertex.y .. "pt) {" .. partVertex.value);
                    tex.print("};");
                    tex.print("\\end{pgfonlayer}");
                end
                print("Vertex " .. partVertex.id .. " had value " .. partVertex.value);
            end
        end
        ::continue::
    end
end

function IsSwimlaneVertex(cell)
    local isSwimlineCell = cell._attr and cell._attr.style and string.find(cell._attr.style, "shape=umlLifeline");
    return isSwimlineCell;
end

function Dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. Dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function ReadVertices(diagramRootNode, scale, maxY)
    local vertices = {};
    local verticesToPrint = {};
    local cellIdsIgnored = {};
    local edges = {};

    for i, cell in pairs(diagramRootNode.mxCell) do
        print("Cell " .. tostring(i));
        print("\tId: " .. cell._attr.id);
        if cell._attr.value then
            print("\tValue: " .. cell._attr.value);
        end
        if cell._attr.edge == "1" then
            print("\tIs an Edge.");

            local edge = {};
            edge.id = cell._attr.id;
            edge.value = cell._attr.value;
            edge.source = cell._attr.source;
            edge.target = cell._attr.target;

            edges[edge.id] = edge;
        elseif cell._attr.vertex == "1" then
            print("\tIs a vertex.");

            local vertex = {};
            vertex.children = {};
            vertex.id = cell._attr.id;
            vertex.value = cell._attr.value;
            vertex.parent = cell._attr.parent;
            vertex.shouldPrint = false;
            vertex.isSwimlane = IsSwimlaneVertex(cell);
            local relativeX = 0;
            local relativeY = 0;
            if cell.mxGeometry and cell.mxGeometry._attr.x then
                relativeX = cell.mxGeometry._attr.x * scale;
            end
            if cell.mxGeometry and cell.mxGeometry._attr.y then
                relativeY = cell.mxGeometry._attr.y * scale;
            end

            if (cell._attr.parent) then
                --position relative to parent
                if vertices[vertex.parent] then
                    vertex.x = math.floor(vertices[vertex.parent].x + relativeX);
                    vertex.y = math.floor(vertices[vertex.parent].y - relativeY);
                    vertex.shouldPrint = true;
                    vertices[vertex.parent].children[vertex.id] = vertex;
                elseif cellIdsIgnored[vertex.parent] then
                    --Pseudo-parent is neither vertex or edge. So position absolutely
                    vertex.x = math.floor(relativeX);
                    vertex.y = math.floor(maxY - relativeY);
                    vertex.shouldPrint = true;
                elseif edges[vertex.parent] then
                    --TODO: care about that later!
                else
                    --TODO: Care about this later - maybe store vertex in temporary list and care about lists entries iteratively.
                    print("Error reading parent with ID. " .. vertex.parent .. " Is the parent after child node in xml?");
                    os.exit(1);
                end
            elseif cell.mxGeometry and cell.mxGeometry._attr.x and cell.mxGeometry._attr.y then
                --position absolutely
                vertex.x = math.floor(cell.mxGeometry._attr.x * scale);
                vertex.y = math.floor(maxY - cell.mxGeometry._attr.y * scale);
                vertex.shouldPrint = true;
            end
            if vertex.shouldPrint then
                if cell.mxGeometry._attr.width and cell.mxGeometry._attr.height then
                    vertex.width = math.floor(cell.mxGeometry._attr.width * scale);
                    vertex.height = math.floor(cell.mxGeometry._attr.height * scale);
                end
                print("Vertex " .. vertex.id .. " has geometry " ..
                vertex.x .. "/" .. vertex.y .. " so adding it to the graph.");
            end
            vertices[vertex.id] = vertex;
            if not vertex.parent or not vertices[vertex.parent] then
                verticesToPrint[vertex.id] = vertex;
            end
        else
            cellIdsIgnored[cell._attr.id] = cell._attr.id;
        end
        ::continue::
    end
    return { vertices = verticesToPrint, edges = edges };
end