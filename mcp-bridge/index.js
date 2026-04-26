#!/usr/bin/env node
// Godot MCP Pro bridge: stdio MCP (Claude Code) <-> WebSocket (Godot editor)
// Godot is the WS client; this server listens on ports 6505-6514.

const { WebSocketServer } = require('ws');
const readline = require('readline');

const BASE_PORT = 6505;
const MAX_PORT = 6514;

const godotSockets = new Map(); // port -> WebSocket
const pendingRequests = new Map(); // id -> {resolve, reject, timeoutId}
let nextId = 1;

// Start WebSocket servers on all 10 ports
for (let port = BASE_PORT; port <= MAX_PORT; port++) {
  const wss = new WebSocketServer({ port });
  wss.on('connection', (ws) => {
    godotSockets.set(port, ws);
    process.stderr.write(`[MCP Bridge] Godot connected on port ${port}\n`);

    ws.on('message', (data) => {
      try {
        const msg = JSON.parse(data.toString());
        if (msg.method === 'ping' || msg.method === 'pong') return;
        if (msg.id !== undefined && pendingRequests.has(msg.id)) {
          const { resolve, timeoutId } = pendingRequests.get(msg.id);
          clearTimeout(timeoutId);
          pendingRequests.delete(msg.id);
          resolve(msg);
        }
      } catch (e) {
        process.stderr.write(`[MCP Bridge] Parse error: ${e.message}\n`);
      }
    });

    ws.on('close', () => {
      if (godotSockets.get(port) === ws) {
        godotSockets.delete(port);
        process.stderr.write(`[MCP Bridge] Godot disconnected from port ${port}\n`);
      }
    });

    ws.on('error', () => godotSockets.delete(port));
  });

  wss.on('error', (e) =>
    process.stderr.write(`[MCP Bridge] Port ${port} error: ${e.message}\n`)
  );
}

function getGodotSocket() {
  for (const [, ws] of godotSockets) {
    if (ws.readyState === 1) return ws;
  }
  return null;
}

function sendToGodot(method, params) {
  return new Promise((resolve, reject) => {
    const ws = getGodotSocket();
    if (!ws) {
      reject(new Error('Godot not connected — open Godot with MCP Pro plugin enabled.'));
      return;
    }
    const id = nextId++;
    const timeoutId = setTimeout(() => {
      if (pendingRequests.has(id)) {
        pendingRequests.delete(id);
        reject(new Error(`Timeout waiting for Godot response to '${method}'`));
      }
    }, 30000);
    pendingRequests.set(id, { resolve, reject, timeoutId });
    ws.send(JSON.stringify({ jsonrpc: '2.0', id, method, params: params || {} }));
  });
}

// All tools exposed by Godot MCP Pro 1.12.0
const TOOL_NAMES = [
  'add_animation_track','add_audio_bus','add_audio_bus_effect','add_audio_player',
  'add_autoload','add_gridmap','add_mesh_instance','add_node','add_raycast',
  'add_resource','add_scene_instance','add_state_machine_state',
  'add_state_machine_transition','analyze_scene_complexity','analyze_signal_flow',
  'apply_particle_preset','assert_node_state','assert_screen_text',
  'assign_shader_material','attach_script','bake_navigation_mesh','batch_add_nodes',
  'batch_get_properties','batch_set_property','capture_frames','clear_output',
  'click_button_by_text','collision_layer_info','collision_mask_info',
  'compare_screenshots','connect_signal','create_animation','create_animation_tree',
  'create_particles','create_resource','create_scene','create_script','create_shader',
  'create_theme','cross_scene_set_property','delete_node','delete_scene',
  'deploy_to_android','detect_circular_dependencies','disconnect_signal',
  'duplicate_node','edit_resource','edit_script','edit_shader',
  'execute_editor_script','execute_game_script','export_project',
  'find_nearby_nodes','find_node_references','find_nodes_by_script',
  'find_nodes_by_type','find_nodes_in_group','find_script_references',
  'find_signal_connections','find_ui_elements','find_unused_resources',
  'get_android_preset_info','get_animation_info','get_animation_tree_structure',
  'get_audio_bus_layout','get_audio_info','get_autoload','get_collision_info',
  'get_editor_camera','get_editor_errors','get_editor_performance',
  'get_editor_screenshot','get_export_info','get_filesystem_tree',
  'get_game_node_properties','get_game_scene_tree','get_game_screenshot',
  'get_input_actions','get_navigation_info','get_node_groups','get_node_properties',
  'get_open_scripts','get_output_log','get_particle_info','get_performance_monitors',
  'get_physics_layers','get_project_info','get_project_settings',
  'get_project_statistics','get_resource_preview','get_scene_dependencies',
  'get_scene_exports','get_scene_file_content','get_scene_tree','get_shader_params',
  'get_signals','get_test_report','get_theme_info','list_android_devices',
  'list_animations','list_export_presets','list_scripts','monitor_properties',
  'move_node','move_to','navigate_to','open_scene','play_scene',
  'project_path_to_uid','read_resource','read_script','read_shader',
  'reload_plugin','reload_project','remove_animation','remove_autoload',
  'remove_state_machine_state','remove_state_machine_transition','rename_node',
  'replay_recording','run_stress_test','run_test_scenario','save_scene',
  'search_files','search_in_files','set_anchor_preset','set_animation_keyframe',
  'set_audio_bus','set_auto_dismiss','set_blend_tree_node','set_editor_camera',
  'set_game_node_property','set_input_action','set_navigation_layers',
  'set_node_groups','set_particle_color_gradient','set_particle_material',
  'set_physics_layers','set_project_setting','set_shader_param','set_theme_color',
  'set_theme_constant','set_theme_font_size','set_theme_stylebox','set_tree_parameter',
  'setup_collision','setup_control','setup_environment','setup_lighting',
  'setup_navigation_agent','setup_navigation_region','setup_physics_body',
  'simulate_action','simulate_key','simulate_mouse_click','simulate_mouse_move',
  'simulate_sequence','start_recording','stop_recording','stop_scene',
  'tilemap_clear','tilemap_fill_rect','tilemap_get_cell','tilemap_get_info',
  'tilemap_get_used_cells','tilemap_set_cell','uid_to_project_path','update_property',
  'validate_script','wait_for_node','watch_signals',
];

const TOOLS = TOOL_NAMES.map((name) => ({
  name,
  description: `Godot editor command: ${name}`,
  inputSchema: { type: 'object', additionalProperties: true },
}));

// MCP stdio
const rl = readline.createInterface({ input: process.stdin });

function send(msg) {
  process.stdout.write(JSON.stringify(msg) + '\n');
}

rl.on('line', async (line) => {
  line = line.trim();
  if (!line) return;

  let msg;
  try { msg = JSON.parse(line); } catch { return; }

  const { id, method, params } = msg;

  switch (method) {
    case 'initialize':
      send({
        jsonrpc: '2.0', id,
        result: {
          protocolVersion: '2024-11-05',
          capabilities: { tools: {} },
          serverInfo: { name: 'godot-mcp-bridge', version: '1.12.0' },
        },
      });
      break;

    case 'notifications/initialized':
      break;

    case 'tools/list':
      send({ jsonrpc: '2.0', id, result: { tools: TOOLS } });
      break;

    case 'tools/call': {
      const toolName = params?.name;
      const toolArgs = params?.arguments || {};
      try {
        const result = await sendToGodot(toolName, toolArgs);
        if (result.error) {
          send({
            jsonrpc: '2.0', id,
            result: {
              content: [{ type: 'text', text: JSON.stringify(result.error, null, 2) }],
              isError: true,
            },
          });
        } else {
          send({
            jsonrpc: '2.0', id,
            result: {
              content: [{ type: 'text', text: JSON.stringify(result.result, null, 2) }],
            },
          });
        }
      } catch (e) {
        send({
          jsonrpc: '2.0', id,
          result: { content: [{ type: 'text', text: e.message }], isError: true },
        });
      }
      break;
    }

    default:
      if (id !== undefined) {
        send({
          jsonrpc: '2.0', id,
          error: { code: -32601, message: `Method not found: ${method}` },
        });
      }
  }
});

process.stderr.write('[MCP Bridge] Godot MCP Pro bridge started. Waiting for Godot on ports 6505-6514...\n');
