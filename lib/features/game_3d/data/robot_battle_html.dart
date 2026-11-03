import '../../character_3d/data/selected_fighter_service.dart';

/// Mã nguồn HTML, CSS và JavaScript của Three.js 3D Battle Arena.
/// Đã được nâng cấp toàn diện:
/// 1. Đồng bộ tướng từ Tab 2 (Tên, Màu Neon, Tốc độ, Lực đánh, Máu tối đa).
/// 2. Hệ thống Kỹ Năng Đấu Võ:
///    - Đấm Cơ Bản (Basic Punch) tích Năng Lượng.
///    - Kỹ năng 1: ⚡ Lướt Tốc Biến (Dash Strike) xuyên phá.
///    - Kỹ năng 2: 🔥 Siêu Tuyệt Kỹ Bão Sấm Sét (Ultimate Shockwave 360°).
/// 3. Hệ thống Âm thanh Chân thực Web Audio Synth (Zero-Download SFX: Đấm, Nhảy, Lướt, Nổ, Ulti).
/// 4. Hệ thống Combo, Hiển thị Sát thương Bạo Kích bay lơ lửng.
/// 5. Hệ thống Bản đồ đa dạng:
///    - Map 1: Đấu Trường Arena (.GLB).
///    - Map 2: Hầm Ngục Lâu Đài (.GLB).
///    - Map 3: Trạm Không Gian Sci-Fi (.GLB).
///    - Map 4: Đấu Trường Cyberpunk Neon 3D (Procedural Built-in) chạy 100% mượt kể cả offline.
/// 6. Cơ chế chống rơi vực vô tận (Quantum Teleport / Fall Protection).
/// 7. AI Đối thủ thông minh (áp sát, đảo vòng né đòn, phản kích).
class RobotBattleHtml {
  RobotBattleHtml._();

  static String getContent({FighterConfig? fighter}) {
    final f = fighter ?? SelectedFighterService.defaultFighter;
    final playerName = f.name;
    final playerColorHex = f.hexColor;
    final playerSpeedFactor = (f.speed / 85.0).clamp(0.8, 1.4);
    final playerPowerFactor = (f.power / 90.0).clamp(0.8, 1.5);
    final playerMaxHp = f.maxHp;

    return '''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Cyber Battle Arena 3D</title>
  <style>
    * {
      box-sizing: border-box;
      user-select: none;
      -webkit-user-select: none;
      touch-action: none;
      margin: 0;
      padding: 0;
    }
    body, html {
      width: 100%;
      height: 100%;
      overflow: hidden;
      background-color: #050811;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    #canvas-container {
      width: 100%;
      height: 100%;
      position: absolute;
      top: 0;
      left: 0;
    }

    /* BẢNG CHỈ SỐ MÁU & NĂNG LƯỢNG (CYBER HUD) */
    #top-hud {
      position: absolute;
      top: 10px;
      left: 10px;
      right: 10px;
      display: flex;
      justify-content: space-between;
      gap: 10px;
      z-index: 25;
      pointer-events: none;
    }
    .fighter-hud-card {
      flex: 1;
      max-width: 240px;
      background: rgba(8, 14, 28, 0.9);
      border-radius: 12px;
      padding: 8px 12px;
      border: 1.5px solid rgba(0, 229, 255, 0.5);
      backdrop-filter: blur(8px);
      box-shadow: 0 4px 18px rgba(0, 0, 0, 0.6);
    }
    .hud-header {
      display: flex;
      justify-content: space-between;
      font-size: 11px;
      font-weight: 900;
      letter-spacing: 0.5px;
      margin-bottom: 5px;
    }
    .bar-wrapper {
      position: relative;
      margin-bottom: 4px;
    }
    .bar-bg {
      width: 100%;
      height: 10px;
      background: rgba(255, 255, 255, 0.12);
      border-radius: 6px;
      overflow: hidden;
    }
    .bar-fill {
      height: 100%;
      border-radius: 6px;
      transition: width 0.22s cubic-bezier(0.4, 0, 0.2, 1);
    }
    #player-hp-fill {
      background: linear-gradient(90deg, $playerColorHex, #00e5ff);
      box-shadow: 0 0 10px $playerColorHex;
    }
    #player-energy-fill {
      background: linear-gradient(90deg, #f59e0b, #eab308, #facc15);
      box-shadow: 0 0 10px #f59e0b;
    }
    #enemy-hp-fill {
      background: linear-gradient(90deg, #f43f5e, #e11d48);
      box-shadow: 0 0 10px #f43f5e;
    }
    .energy-bar-bg {
      height: 5px;
    }

    /* THANH CHỌN BẢN ĐỒ */
    #map-bar {
      position: absolute;
      top: 74px;
      left: 10px;
      right: 10px;
      display: flex;
      gap: 6px;
      overflow-x: auto;
      padding-bottom: 4px;
      z-index: 25;
      scrollbar-width: none;
    }
    #map-bar::-webkit-scrollbar { display: none; }
    .map-btn {
      background: rgba(10, 16, 32, 0.88);
      border: 1.5px solid rgba(0, 229, 255, 0.35);
      color: #bae6fd;
      font-size: 10px;
      font-weight: bold;
      padding: 6px 12px;
      border-radius: 14px;
      white-space: nowrap;
      cursor: pointer;
      backdrop-filter: blur(6px);
      transition: all 0.15s ease;
    }
    .map-btn.active {
      background: #00e5ff;
      color: #030712;
      border-color: #ffffff;
      box-shadow: 0 0 14px rgba(0, 229, 255, 0.85);
    }

    /* CẦN JOYSTICK DI CHUYỂN */
    #joystick-zone {
      position: absolute;
      bottom: 20px;
      left: 16px;
      width: 120px;
      height: 120px;
      border-radius: 50%;
      background: radial-gradient(circle, rgba(0, 229, 255, 0.15) 0%, rgba(5, 8, 17, 0.75) 70%);
      border: 2px solid rgba(0, 229, 255, 0.45);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 25;
      box-shadow: 0 0 20px rgba(0, 229, 255, 0.25);
    }
    #joystick-knob {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background: radial-gradient(circle, #ffffff 10%, #00e5ff 85%);
      box-shadow: 0 0 18px rgba(0, 229, 255, 0.95);
      position: absolute;
      pointer-events: none;
    }

    /* BẢNG PHÍM KỸ NĂNG VÀ HÀNH ĐỘNG CHIẾN ĐẤU */
    #actions-container {
      position: absolute;
      bottom: 16px;
      right: 14px;
      display: grid;
      grid-template-columns: repeat(2, auto);
      gap: 8px;
      z-index: 25;
    }
    .btn-skill {
      border: 1.5px solid;
      color: white;
      font-weight: 900;
      font-size: 11px;
      padding: 10px 14px;
      border-radius: 20px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: all 0.08s ease;
      box-shadow: 0 4px 14px rgba(0, 0, 0, 0.4);
    }
    .btn-skill:active {
      transform: scale(0.92);
    }
    #btn-punch {
      background: linear-gradient(135deg, #ef4444, #b91c1c);
      border-color: #fca5a5;
      box-shadow: 0 0 16px rgba(239, 68, 68, 0.65);
    }
    #btn-dash {
      background: linear-gradient(135deg, #0ea5e9, #0284c7);
      border-color: #7dd3fc;
      box-shadow: 0 0 16px rgba(14, 165, 233, 0.65);
    }
    #btn-jump {
      background: linear-gradient(135deg, #8b5cf6, #6d28d9);
      border-color: #c4b5fd;
      box-shadow: 0 0 16px rgba(139, 92, 246, 0.65);
    }
    #btn-ultimate {
      background: linear-gradient(135deg, #f59e0b, #d97706);
      border-color: #fde68a;
      box-shadow: 0 0 22px rgba(245, 158, 11, 0.85);
      position: relative;
      overflow: hidden;
    }
    #btn-ultimate.ready {
      background: linear-gradient(135deg, #f59e0b, #dc2626);
      border-color: #ffffff;
      animation: pulseGlow 1s infinite alternate;
    }
    @keyframes pulseGlow {
      from { box-shadow: 0 0 15px #f59e0b; }
      to { box-shadow: 0 0 28px #ef4444; }
    }

    /* THANH CÔNG CỤ PHỤ (CAMERA & RESET & AI) */
    #sub-tools {
      position: absolute;
      bottom: 155px;
      left: 16px;
      display: flex;
      flex-direction: column;
      gap: 6px;
      z-index: 25;
    }
    .sub-btn {
      width: 38px;
      height: 38px;
      border-radius: 50%;
      background: rgba(8, 14, 28, 0.88);
      border: 1.5px solid rgba(0, 229, 255, 0.5);
      color: #00e5ff;
      font-size: 15px;
      font-weight: bold;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.5);
      cursor: pointer;
    }
    .sub-btn:active {
      transform: scale(0.9);
      background: #00e5ff;
      color: black;
    }

    /* POPUP CHỮ SÁT THƯƠNG & COMBO */
    .damage-text {
      position: absolute;
      color: #ff3366;
      font-weight: 900;
      font-size: 18px;
      pointer-events: none;
      animation: popUp 0.8s forwards;
      text-shadow: 0 0 10px rgba(0, 0, 0, 0.95), 0 0 20px #ff0055;
      z-index: 40;
    }
    .combo-text {
      position: absolute;
      color: #facc15;
      font-weight: 900;
      font-size: 22px;
      pointer-events: none;
      animation: popUp 0.9s forwards;
      text-shadow: 0 0 12px rgba(0, 0, 0, 0.95), 0 0 25px #f59e0b;
      z-index: 40;
    }
    @keyframes popUp {
      0% { opacity: 1; transform: translateY(0) scale(1.4); }
      100% { opacity: 0; transform: translateY(-45px) scale(0.9); }
    }

    /* MÀN HÌNH THẮNG / THUA OVERLAY */
    #victory-modal {
      display: none;
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(5, 8, 17, 0.85);
      backdrop-filter: blur(8px);
      z-index: 100;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      padding: 20px;
    }
    #victory-modal h1 {
      font-size: 32px;
      font-weight: 900;
      margin-bottom: 8px;
    }
    #victory-modal p {
      color: #94a3b8;
      font-size: 14px;
      margin-bottom: 24px;
    }
    .modal-btn {
      background: linear-gradient(135deg, #00e5ff, #0284c7);
      border: none;
      color: #030712;
      font-weight: 900;
      font-size: 14px;
      padding: 12px 28px;
      border-radius: 24px;
      cursor: pointer;
      box-shadow: 0 0 22px rgba(0, 229, 255, 0.7);
    }

    #loading-overlay {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: #050811;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: #00e5ff;
      font-size: 13px;
      font-weight: bold;
      z-index: 120;
      transition: opacity 0.4s;
    }
    .spinner {
      width: 44px;
      height: 44px;
      border: 4px solid rgba(0, 229, 255, 0.2);
      border-top-color: #00e5ff;
      border-radius: 50%;
      animation: spin 0.8s infinite linear;
      margin-bottom: 12px;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }

    /* MEDIA QUERIES RESPONSIVE CHO MỌI THIẾT BỊ */
    @media (max-height: 520px) {
      #top-hud { top: 6px; }
      .fighter-hud-card { padding: 4px 8px; max-width: 170px; }
      #map-bar { top: 54px; }
      #actions-container { bottom: 8px; right: 8px; gap: 6px; }
      .btn-skill { padding: 6px 10px; font-size: 10px; }
      #joystick-zone { width: 95px; height: 95px; bottom: 8px; left: 10px; }
      #joystick-knob { width: 38px; height: 38px; }
      #sub-tools { bottom: 110px; left: 10px; gap: 4px; }
      .sub-btn { width: 32px; height: 32px; font-size: 13px; }
    }
    @media (max-width: 390px) {
      .fighter-hud-card { padding: 5px 8px; font-size: 10px; }
      .btn-skill { padding: 8px 10px; font-size: 10px; }
    }
  </style>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
</head>
<body>
  <div id="loading-overlay">
    <div class="spinner"></div>
    <div id="loading-text">Đang tải Đấu Trường & Vũ Khí 3D...</div>
  </div>

  <!-- HUD ĐẦU MÀN HÌNH -->
  <div id="top-hud">
    <div class="fighter-hud-card" style="border-color: $playerColorHex;">
      <div class="hud-header" style="color: $playerColorHex;">
        <span id="player-name-hud">$playerName</span>
        <span id="player-hp-num">$playerMaxHp HP</span>
      </div>
      <div class="bar-wrapper">
        <div class="bar-bg">
          <div id="player-hp-fill" class="bar-fill" style="width: 100%;"></div>
        </div>
      </div>
      <div class="bar-wrapper">
        <div class="bar-bg energy-bar-bg">
          <div id="player-energy-fill" class="bar-fill" style="width: 25%;"></div>
        </div>
      </div>
    </div>

    <div class="fighter-hud-card" style="border-color: #f43f5e;">
      <div class="hud-header" style="color: #f43f5e;">
        <span>MECHA CYBER RED</span>
        <span id="enemy-hp-num">100 HP</span>
      </div>
      <div class="bar-wrapper">
        <div class="bar-bg">
          <div id="enemy-hp-fill" class="bar-fill" style="width: 100%;"></div>
        </div>
      </div>
    </div>
  </div>

  <!-- THANH CHỌN BẢN ĐỒ -->
  <div id="map-bar">
    <button class="map-btn active" id="tab-cyber" onclick="changeMap('cyber')">Đấu Trường Cyberpunk (Neon 3D)</button>
    <button class="map-btn" id="tab-arena" onclick="changeMap('arena')">Đấu Trường Cổ Điển (.GLB)</button>
    <button class="map-btn" id="tab-dungeon" onclick="changeMap('dungeon')">Hầm Ngục Pháo Đài (.GLB)</button>
    <button class="map-btn" id="tab-space" onclick="changeMap('space')">Trạm Không Gian (.GLB)</button>
    <button class="map-btn" id="tab-custom" onclick="promptCustomMap()">Nhập URL Bản Đồ .GLB</button>
  </div>

  <div id="canvas-container"></div>

  <!-- CỤM CÔNG CỤ PHỤ (CAMERA / AI / RESET) -->
  <div id="sub-tools">
    <div class="sub-btn" onclick="zoomCam(-2)" title="Phóng to">+</div>
    <div class="sub-btn" onclick="zoomCam(2)" title="Thu nhỏ">-</div>
    <div class="sub-btn" onclick="resetCamView()" title="Góc nhìn chuẩn">CAM</div>
    <div class="sub-btn" onclick="toggleAI()" id="btn-ai-toggle" title="Bật/Tắt AI">AI</div>
    <div class="sub-btn" onclick="resetBattle()" title="Chơi lại">RST</div>
  </div>

  <!-- CẦN JOYSTICK -->
  <div id="joystick-zone">
    <div id="joystick-knob"></div>
  </div>

  <!-- BẢNG PHÍM HÀNH ĐỘNG CHIẾN ĐẤU -->
  <div id="actions-container">
    <button class="btn-skill" id="btn-punch">ĐẤM (PUNCH)</button>
    <button class="btn-skill" id="btn-dash">LƯỚT (DASH)</button>
    <button class="btn-skill" id="btn-jump">NHẢY (JUMP)</button>
    <button class="btn-skill" id="btn-ultimate">SIÊU TUYỆT KỸ</button>
  </div>

  <!-- OVERLAY CHIẾN THẮNG / THẤT BẠI -->
  <div id="victory-modal">
    <h1 id="victory-title" style="color: #00e5ff;">CHIẾN THẮNG!</h1>
    <p id="victory-desc">Bạn đã xuất sắc hạ gục đối thủ Mecha trong đấu trường 3D!</p>
    <button class="modal-btn" onclick="resetBattle()">CHƠI TRẬN MỚI</button>
  </div>

  <script>
    // ==========================================
    // 1. TỔNG HỢP ÂM THANH WEB AUDIO SYNTHESIZER
    // ==========================================
    let audioCtx = null;
    function getAudioCtx() {
      if (!audioCtx) {
        audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      }
      if (audioCtx.state === 'suspended') {
        audioCtx.resume();
      }
      return audioCtx;
    }

    function sfxPunch() {
      try {
        const ctx = getAudioCtx();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(140, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(35, ctx.currentTime + 0.12);
        gain.gain.setValueAtTime(0.7, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.14);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.15);
      } catch(_) {}
    }

    function sfxDash() {
      try {
        const ctx = getAudioCtx();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(450, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(120, ctx.currentTime + 0.22);
        gain.gain.setValueAtTime(0.45, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.25);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.26);
      } catch(_) {}
    }

    function sfxJump() {
      try {
        const ctx = getAudioCtx();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(180, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(520, ctx.currentTime + 0.18);
        gain.gain.setValueAtTime(0.4, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.2);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.21);
      } catch(_) {}
    }

    function sfxExplosion() {
      try {
        const ctx = getAudioCtx();
        const bufferSize = ctx.sampleRate * 0.45;
        const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
        const data = buffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
          data[i] = Math.random() * 2 - 1;
        }
        const noise = ctx.createBufferSource();
        noise.buffer = buffer;
        const filter = ctx.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.setValueAtTime(550, ctx.currentTime);
        filter.frequency.exponentialRampToValueAtTime(40, ctx.currentTime + 0.4);
        const gain = ctx.createGain();
        gain.gain.setValueAtTime(0.85, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.45);
        noise.connect(filter);
        filter.connect(gain);
        gain.connect(ctx.destination);
        noise.start();
      } catch(_) {}
    }

    function sfxUlt() {
      try {
        const ctx = getAudioCtx();
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(90, ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.35);
        osc.frequency.exponentialRampToValueAtTime(60, ctx.currentTime + 0.7);
        gain.gain.setValueAtTime(0.9, ctx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.75);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start();
        osc.stop(ctx.currentTime + 0.8);
      } catch(_) {}
    }

    // ==========================================
    // 2. BIẾN TRẠNG THÁI VÀ THÔNG SỐ NHÂN VẬT
    // ==========================================
    const PLAYER_CONFIG = {
      name: '$playerName',
      hexColor: '$playerColorHex',
      speedFactor: $playerSpeedFactor,
      powerFactor: $playerPowerFactor,
      maxHp: $playerMaxHp,
      baseSpeed: 5.2 * $playerSpeedFactor,
      baseDamage: 22 * $playerPowerFactor
    };

    let scene, camera, renderer, clock;
    let playerModel, playerMixer, playerActions = {}, playerActiveAction;
    let enemyModel, enemyMixer, enemyActions = {}, enemyActiveAction;
    let isMoving = false;

    let isGrounded = true;
    let verticalVelocity = 0;
    const gravity = 22.0;
    const jumpForce = 8.8;

    let enemyGrounded = true;
    let enemyVerticalVelocity = 0;

    const playerKnockback = { vx: 0, vy: 0, vz: 0 };
    const enemyKnockback = { vx: 0, vy: 0, vz: 0 };
    let cameraShake = 0;

    let playerHP = PLAYER_CONFIG.maxHp;
    let enemyHP = 100;
    let playerEnergy = 30; // 0 -> 100
    let isPlayerDead = false;
    let isEnemyDead = false;
    let enemyAIMode = true;
    let comboCount = 0;
    let comboTimer = 0;

    let camDistance = 9.0;
    let camAngle = 0.0;
    let camPitch = 0.38;

    const mapColliderMeshes = [];
    let currentMapObject = null;
    let solidObstacles = [];
    let jumpPads = [];
    const particles = [];

    const downRay = new THREE.Raycaster();
    const downDir = new THREE.Vector3(0, -1, 0);
    const forwardRay = new THREE.Raycaster();

    const GLB_URLS = {
      arena: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/collision-world.glb',
      dungeon: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/dungeon_warkarma.glb',
      space: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/space_ship_hallway.glb'
    };

    init();
    animate();

    function init() {
      const container = document.getElementById('canvas-container');
      clock = new THREE.Clock();

      scene = new THREE.Scene();
      scene.background = new THREE.Color(0x050811);
      scene.fog = new THREE.FogExp2(0x050811, 0.015);

      camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 160);

      renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: 'high-performance' });
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2.0));
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.shadowMap.enabled = true;
      renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      container.appendChild(renderer.domElement);

      const hemiLight = new THREE.HemisphereLight(0xdbeafe, 0x0f172a, 0.85);
      scene.add(hemiLight);

      const dirLight = new THREE.DirectionalLight(0x00e5ff, 1.4);
      dirLight.position.set(16, 26, 16);
      dirLight.castShadow = true;
      dirLight.shadow.mapSize.width = 1024;
      dirLight.shadow.mapSize.height = 1024;
      dirLight.shadow.camera.near = 0.5;
      dirLight.shadow.camera.far = 70;
      dirLight.shadow.camera.left = -25;
      dirLight.shadow.camera.right = 25;
      dirLight.shadow.camera.top = 25;
      dirLight.shadow.camera.bottom = -25;
      scene.add(dirLight);

      // Khởi tạo Map 1: Cyberpunk Neon Đấu Trường
      buildCyberpunkMap();

      // Tải Robot 3D cho Player và Enemy
      loadFighters();

      setupTouchControls();
      window.addEventListener('resize', onResize);
    }

    // ==========================================
    // 3. XÂY DỰNG MAP NỘI TẠI CYBERPUNK NEON 3D
    // ==========================================
    function buildCyberpunkMap() {
      clearMap();

      const mapGroup = new THREE.Group();

      // Sàn chính Đấu Trường Neon tròn có phản quang
      const arenaRadius = 24;
      const floorGeo = new THREE.CylinderGeometry(arenaRadius, arenaRadius + 2, 1.2, 48);
      const floorMat = new THREE.MeshStandardMaterial({
        color: 0x0a1122,
        roughness: 0.25,
        metalness: 0.75
      });
      const mainFloor = new THREE.Mesh(floorGeo, floorMat);
      mainFloor.position.y = -0.6;
      mainFloor.receiveShadow = true;
      mapGroup.add(mainFloor);
      mapColliderMeshes.push(mainFloor);

      // Viền sáng Neon ngoài rìa sàn
      const ringGeo = new THREE.RingGeometry(arenaRadius - 0.4, arenaRadius + 0.4, 48);
      const ringMat = new THREE.MeshBasicMaterial({ color: 0x00e5ff, side: THREE.DoubleSide });
      const ring = new THREE.Mesh(ringGeo, ringMat);
      ring.rotation.x = -Math.PI / 2;
      ring.position.y = 0.02;
      mapGroup.add(ring);

      // Vòng lưới tâm đấu trường
      const innerRingGeo = new THREE.RingGeometry(6.8, 7.2, 32);
      const innerRingMat = new THREE.MeshBasicMaterial({ color: 0xf59e0b, side: THREE.DoubleSide });
      const innerRing = new THREE.Mesh(innerRingGeo, innerRingMat);
      innerRing.rotation.x = -Math.PI / 2;
      innerRing.position.y = 0.02;
      mapGroup.add(innerRing);

      // Bục nâng cao tầng 2 ở góc
      function createPlatform(x, z, w, h, d, color = 0x1e293b) {
        const pGeo = new THREE.BoxGeometry(w, h, d);
        const pMat = new THREE.MeshStandardMaterial({ color: color, roughness: 0.3, metalness: 0.6 });
        const pMesh = new THREE.Mesh(pGeo, pMat);
        pMesh.position.set(x, h / 2, z);
        pMesh.castShadow = true;
        pMesh.receiveShadow = true;
        mapGroup.add(pMesh);
        mapColliderMeshes.push(pMesh);

        // Đèn viền bục
        const borderGeo = new THREE.BoxGeometry(w + 0.1, 0.1, d + 0.1);
        const borderMat = new THREE.MeshBasicMaterial({ color: 0x38bdf8 });
        const border = new THREE.Mesh(borderGeo, borderMat);
        border.position.set(x, h + 0.05, z);
        mapGroup.add(border);
      }

      // 4 Bục cao 4 góc
      createPlatform(10, 10, 6, 2.0, 6);
      createPlatform(-10, 10, 6, 1.4, 6);
      createPlatform(10, -10, 6, 1.4, 6);
      createPlatform(-10, -10, 6, 2.0, 6);

      // Cầu dốc dẫn lên bục
      function createRamp(x, z, rotY, w, l, h) {
        const rampGeo = new THREE.BoxGeometry(w, 0.4, l);
        const rampMat = new THREE.MeshStandardMaterial({ color: 0x334155, roughness: 0.4 });
        const ramp = new THREE.Mesh(rampGeo, rampMat);
        ramp.position.set(x, h / 2, z);
        ramp.rotation.y = rotY;
        ramp.rotation.x = Math.atan2(h, l);
        ramp.receiveShadow = true;
        mapGroup.add(ramp);
        mapColliderMeshes.push(ramp);
      }
      createRamp(10, 5, 0, 3, 5, 2.0);
      createRamp(-10, 5, 0, 3, 4, 1.4);

      // 4 Cột Tháp Laser Năng Lượng Cyber
      for (let i = 0; i < 4; i++) {
        const ang = (i * Math.PI) / 2 + Math.PI / 4;
        const tx = Math.sin(ang) * (arenaRadius - 3.5);
        const tz = Math.cos(ang) * (arenaRadius - 3.5);

        const pillarGeo = new THREE.CylinderGeometry(0.8, 1.2, 9, 16);
        const pillarMat = new THREE.MeshStandardMaterial({ color: 0x0f172a, roughness: 0.3, metalness: 0.8 });
        const pillar = new THREE.Mesh(pillarGeo, pillarMat);
        pillar.position.set(tx, 4.5, tz);
        pillar.castShadow = true;
        mapGroup.add(pillar);
        mapColliderMeshes.push(pillar);

        const beaconGeo = new THREE.SphereGeometry(0.6, 16, 16);
        const beaconMat = new THREE.MeshBasicMaterial({ color: i % 2 === 0 ? 0x00e5ff : 0xef4444 });
        const beacon = new THREE.Mesh(beaconGeo, beaconMat);
        beacon.position.set(tx, 9.4, tz);
        mapGroup.add(beacon);
      }

      currentMapObject = mapGroup;
      scene.add(currentMapObject);

      spawnInteractiveProps();
      hideLoading();
    }

    function clearMap() {
      if (currentMapObject) {
        scene.remove(currentMapObject);
        currentMapObject.traverse(c => {
          if (c.geometry) c.geometry.dispose();
          if (c.material) {
            if (Array.isArray(c.material)) c.material.forEach(m => m.dispose());
            else c.material.dispose();
          }
        });
      }
      mapColliderMeshes.length = 0;
      solidObstacles.forEach(obs => {
        scene.remove(obs.mesh);
        if (obs.mesh.geometry) obs.mesh.geometry.dispose();
      });
      solidObstacles.length = 0;
      jumpPads.forEach(p => scene.remove(p.mesh));
      jumpPads.length = 0;
    }

    function spawnInteractiveProps() {
      const crateMat = new THREE.MeshStandardMaterial({ color: 0xf59e0b, roughness: 0.3, metalness: 0.4 });
      const barrelMat = new THREE.MeshStandardMaterial({ color: 0xdc2626, roughness: 0.2, metalness: 0.6 });

      function addBox(x, y, z, w, h, d, mat, isDynamic = true, extra = {}) {
        const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
        mesh.position.set(x, y, z);
        mesh.castShadow = true;
        mesh.receiveShadow = true;
        scene.add(mesh);
        solidObstacles.push({
          type: 'box',
          mesh: mesh,
          w: w, h: h, d: d,
          halfW: w / 2, halfH: h / 2, halfD: d / 2,
          isDynamic: isDynamic,
          vx: 0, vy: 0, vz: 0, rotVx: 0,
          defaultY: y,
          ...extra
        });
      }

      // Thùng gỗ
      addBox(-4, 0.6, 2, 1.2, 1.2, 1.2, crateMat);
      addBox(-2.6, 0.6, 2, 1.2, 1.2, 1.2, crateMat);
      addBox(-3.3, 1.8, 2, 1.2, 1.2, 1.2, crateMat);

      // Thùng thuốc nổ đỏ (Boom Barrel)
      const bMesh = new THREE.Mesh(new THREE.CylinderGeometry(0.65, 0.65, 1.6, 24), barrelMat);
      bMesh.position.set(4, 0.8, -3);
      bMesh.castShadow = true;
      scene.add(bMesh);
      solidObstacles.push({
        type: 'box',
        mesh: bMesh,
        w: 1.3, h: 1.6, d: 1.3,
        halfW: 0.65, halfH: 0.8, halfD: 0.65,
        isDynamic: true,
        isBarrel: true,
        vx: 0, vy: 0, vz: 0,
        defaultY: 0.8
      });

      // Jump Pad Bệ phóng siêu cao
      const padGeo = new THREE.CylinderGeometry(1.6, 1.8, 0.18, 32);
      const padMat = new THREE.MeshStandardMaterial({
        color: 0x00e5ff,
        emissive: 0x0088aa,
        roughness: 0.2,
        metalness: 0.9
      });
      const pad = new THREE.Mesh(padGeo, padMat);
      pad.position.set(0, 0.09, -7);
      scene.add(pad);
      jumpPads.push({ mesh: pad, x: 0, z: -7 });
    }

    function changeMap(key, customUrl = null) {
      document.querySelectorAll('.map-btn').forEach(b => b.classList.remove('active'));
      const activeBtn = document.getElementById('tab-' + key);
      if (activeBtn) activeBtn.classList.add('active');

      if (key === 'cyber') {
        buildCyberpunkMap();
        resetBattle();
        return;
      }

      const url = customUrl || GLB_URLS[key];
      if (!url) return;

      showLoading('Đang tải Map 3D (.GLB)...');
      clearMap();

      const loader = new THREE.GLTFLoader();
      loader.load(url, function(gltf) {
        currentMapObject = gltf.scene;
        if (key === 'arena') currentMapObject.scale.set(1.15, 1.15, 1.15);
        else if (key === 'dungeon') currentMapObject.scale.set(0.75, 0.75, 0.75);
        else currentMapObject.scale.set(1.0, 1.0, 1.0);

        currentMapObject.traverse(child => {
          if (child.isMesh) {
            child.castShadow = true;
            child.receiveShadow = true;
            mapColliderMeshes.push(child);
          }
        });
        scene.add(currentMapObject);
        spawnInteractiveProps();
        resetBattle();
        hideLoading();
        spawnPopup(new THREE.Vector3(0, 2, 0), 'ĐÃ TẢI XONG BẢN ĐỒ!');
      }, undefined, function() {
        alert('Lỗi tải file .GLB. Chuyển về Đấu Trường Cyberpunk!');
        buildCyberpunkMap();
      });
    }

    function promptCustomMap() {
      const url = prompt('Nhập URL file 3D Map (.glb):', GLB_URLS.arena);
      if (url && url.trim().length > 5) {
        changeMap('custom', url.trim());
      }
    }

    // ==========================================
    // 4. TẢI MÔ HÌNH VÀ VẬT LÝ NHÂN VẬT
    // ==========================================
    function loadFighters() {
      const loader = new THREE.GLTFLoader();
      const modelUrl = 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/RobotExpressive/RobotExpressive.glb';

      loader.load(modelUrl, function (gltf) {
        playerModel = gltf.scene;
        playerModel.scale.set(0.65, 0.65, 0.65);
        playerModel.position.set(0, 0, 0);

        // Đổi màu sắc Robot người chơi theo Tướng đã chọn ở Tab 2
        playerModel.traverse(obj => {
          if (obj.isMesh) {
            obj.castShadow = true;
            obj.receiveShadow = true;
            if (obj.material && (obj.name.includes('Body') || obj.name.includes('Head'))) {
              obj.material = obj.material.clone();
              obj.material.color.set(PLAYER_CONFIG.hexColor);
            }
          }
        });
        scene.add(playerModel);

        playerMixer = new THREE.AnimationMixer(playerModel);
        gltf.animations.forEach(clip => {
          playerActions[clip.name] = playerMixer.clipAction(clip);
        });
        playerActiveAction = playerActions['Idle'];
        if (playerActiveAction) playerActiveAction.play();

        // Tải Đối thủ Mecha Đỏ
        loader.load(modelUrl, function (gltf2) {
          enemyModel = gltf2.scene;
          enemyModel.scale.set(0.65, 0.65, 0.65);
          enemyModel.position.set(0, 0, 5.5);

          enemyModel.traverse(obj => {
            if (obj.isMesh) {
              obj.castShadow = true;
              obj.receiveShadow = true;
              if (obj.material && (obj.name.includes('Body') || obj.name.includes('Head'))) {
                obj.material = obj.material.clone();
                obj.material.color.setHex(0xe11d48);
              }
            }
          });
          scene.add(enemyModel);

          enemyMixer = new THREE.AnimationMixer(enemyModel);
          gltf2.animations.forEach(clip => {
            enemyActions[clip.name] = enemyMixer.clipAction(clip);
          });
          enemyActiveAction = enemyActions['Idle'];
          if (enemyActiveAction) enemyActiveAction.play();
        });
      });
    }

    function showLoading(msg) {
      const el = document.getElementById('loading-overlay');
      el.style.display = 'flex';
      el.style.opacity = '1';
      document.getElementById('loading-text').innerText = msg;
    }
    function hideLoading() {
      const el = document.getElementById('loading-overlay');
      el.style.opacity = '0';
      setTimeout(() => el.style.display = 'none', 400);
    }

    // ==========================================
    // 5. ĐỘNG CƠ RAYCASTING VA CHẠM & TÍNH ĐỘ CAO
    // ==========================================
    function getGroundHeightAt(x, z, currentY) {
      let floorY = 0;
      if (mapColliderMeshes.length > 0) {
        downRay.set(new THREE.Vector3(x, currentY + 1.8, z), downDir);
        downRay.far = 18.0;
        const hits = downRay.intersectObjects(mapColliderMeshes, false);
        if (hits.length > 0) {
          for (let i = 0; i < hits.length; i++) {
            const hit = hits[i];
            const hitY = hit.point.y;
            let walkable = true;
            if (hit.face && hit.face.normal) {
              const wn = hit.face.normal.clone().transformDirection(hit.object.matrixWorld);
              if (wn.y < 0.3) walkable = false;
            }
            if (walkable && currentY >= hitY - 0.7) {
              if (hitY > floorY) { floorY = hitY; break; }
            }
          }
        }
      }

      for (let i = 0; i < solidObstacles.length; i++) {
        const obs = solidObstacles[i];
        if (obs.type === 'box') {
          const hw = obs.halfW + 0.35;
          const hd = obs.halfD + 0.35;
          const bx = obs.mesh.position.x, bz = obs.mesh.position.z;
          const topY = obs.mesh.position.y + obs.halfH;
          if (x >= bx - hw && x <= bx + hw && z >= bz - hd && z <= bz + hd) {
            if (currentY >= topY - 0.65 && topY > floorY) floorY = topY;
          }
        }
      }
      return floorY;
    }

    function resolveCollisions(model, radius = 0.65) {
      const px = model.position.x;
      const py = model.position.y;
      const pz = model.position.z;

      for (let i = 0; i < solidObstacles.length; i++) {
        const obs = solidObstacles[i];
        if (obs.type === 'box') {
          const bx = obs.mesh.position.x, bz = obs.mesh.position.z;
          const topY = obs.mesh.position.y + obs.halfH;
          if (py < topY - 0.25) {
            const minX = bx - obs.halfW - radius, maxX = bx + obs.halfW + radius;
            const minZ = bz - obs.halfD - radius, maxZ = bz + obs.halfD + radius;
            if (px > minX && px < maxX && pz > minZ && pz < maxZ) {
              const dL = px - minX, dR = maxX - px, dT = pz - minZ, dB = maxZ - pz;
              const minD = Math.min(dL, dR, dT, dB);
              if (minD === dL) { model.position.x = minX; if (obs.isDynamic) obs.vx = -4; }
              else if (minD === dR) { model.position.x = maxX; if (obs.isDynamic) obs.vx = 4; }
              else if (minD === dT) { model.position.z = minZ; if (obs.isDynamic) obs.vz = -4; }
              else { model.position.z = maxZ; if (obs.isDynamic) obs.vz = 4; }
            }
          }
        }
      }
    }

    // ==========================================
    // 6. HỆ THỐNG KỸ NĂNG & CHIẾN ĐẤU
    // ==========================================
    function doJump() {
      if (isGrounded && !isPlayerDead) {
        sfxJump();
        verticalVelocity = jumpForce;
        isGrounded = false;
        fadeAction(playerActions, playerActiveAction, 'Jump', 0.12, act => playerActiveAction = act);
        spawnSparks(playerModel.position, 0x38bdf8);
      }
    }

    function doPunch() {
      if (isPlayerDead || !playerActions['Punch']) return;
      sfxPunch();

      fadeAction(playerActions, playerActiveAction, 'Punch', 0.12, act => playerActiveAction = act);
      setTimeout(() => {
        if (!isPlayerDead) fadeAction(playerActions, playerActiveAction, isMoving ? 'Walking' : 'Idle', 0.22, act => playerActiveAction = act);
      }, 900);

      // Tích 12% Năng lượng
      addEnergy(12);

      checkPunchHit();
    }

    function doDash() {
      if (isPlayerDead || playerEnergy < 20) {
        spawnPopup(playerModel.position, 'CẦN 20% NĂNG LƯỢNG');
        return;
      }
      sfxDash();
      addEnergy(-20);

      const fX = Math.sin(playerModel.rotation.y);
      const fZ = Math.cos(playerModel.rotation.y);

      playerKnockback.vx = fX * 26.0;
      playerKnockback.vz = fZ * 26.0;
      cameraShake = 0.2;

      spawnSparks(playerModel.position, 0x00e5ff, 28);
      spawnPopup(playerModel.position, 'TỐC BIẾN (DASH)!');

      if (enemyModel && !isEnemyDead) {
        const dx = enemyModel.position.x - playerModel.position.x;
        const dz = enemyModel.position.z - playerModel.position.z;
        const d = Math.sqrt(dx * dx + dz * dz);
        if (d < 3.2) {
          hitEnemy(28, true);
        }
      }
    }

    function doUltimate() {
      if (isPlayerDead || playerEnergy < 100) {
        spawnPopup(playerModel.position, 'CẦN 100% NĂNG LƯỢNG');
        return;
      }
      sfxUlt();
      addEnergy(-100);

      cameraShake = 0.85;
      spawnExplosion(playerModel.position, 0xf59e0b, 70);
      spawnPopup(playerModel.position, 'BÃO NĂNG LƯỢNG ULTIMATE!');

      if (enemyModel && !isEnemyDead) {
        const dx = enemyModel.position.x - playerModel.position.x;
        const dy = enemyModel.position.y - playerModel.position.y;
        const dz = enemyModel.position.z - playerModel.position.z;
        const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
        if (dist < 8.5) {
          hitEnemy(48, true);
          enemyKnockback.vy = 8.5;
        }
      }

      solidObstacles.forEach(obs => {
        if (!obs.isDynamic) return;
        const ox = obs.mesh.position.x - playerModel.position.x;
        const oz = obs.mesh.position.z - playerModel.position.z;
        const od = Math.sqrt(ox * ox + oz * oz);
        if (od < 8.5 && od > 0.1) {
          obs.vx = (ox / od) * 22;
          obs.vz = (oz / od) * 22;
          obs.vy = 6.0;
        }
      });
    }

    function checkPunchHit() {
      if (!playerModel || !enemyModel || isEnemyDead) return;

      const pX = playerModel.position.x, pY = playerModel.position.y, pZ = playerModel.position.z;
      const dx = enemyModel.position.x - pX;
      const dy = enemyModel.position.y - pY;
      const dz = enemyModel.position.z - pZ;
      const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);

      if (dist < 2.5 && Math.abs(dy) < 1.4) {
        hitEnemy(PLAYER_CONFIG.baseDamage);
      }

      solidObstacles.forEach(obs => {
        if (!obs.isDynamic) return;
        const ox = obs.mesh.position.x - pX;
        const oz = obs.mesh.position.z - pZ;
        const od = Math.sqrt(ox * ox + oz * oz);
        if (od < 2.5) {
          if (obs.isBarrel) explodeBarrel(obs);
          else {
            const fX = Math.sin(playerModel.rotation.y), fZ = Math.cos(playerModel.rotation.y);
            obs.vx = fX * 15; obs.vz = fZ * 15;
            spawnPopup(obs.mesh.position, 'BẬT VĂNG!');
          }
        }
      });
    }

    function hitEnemy(damage, isCrit = false) {
      enemyHP = Math.max(0, enemyHP - damage);
      updateHUD();

      comboCount++;
      comboTimer = 2.0;

      if (comboCount > 1) {
        spawnComboPopup(enemyModel.position, comboCount + 'x COMBO!');
      } else {
        spawnPopup(enemyModel.position, '-' + Math.round(damage) + ' HP');
      }

      const dx = enemyModel.position.x - playerModel.position.x;
      const dz = enemyModel.position.z - playerModel.position.z;
      const hDist = Math.sqrt(dx * dx + dz * dz) || 1;

      enemyKnockback.vx = (dx / hDist) * 14.0;
      enemyKnockback.vz = (dz / hDist) * 14.0;
      enemyKnockback.vy = 4.0;
      cameraShake = 0.35;

      spawnSparks(enemyModel.position.clone().add(new THREE.Vector3(0, 1.2, 0)), 0xff0055);
      flashMesh(enemyModel);

      if (enemyHP <= 0) {
        isEnemyDead = true;
        fadeAction(enemyActions, enemyActiveAction, 'Death', 0.2, act => enemyActiveAction = act);
        setTimeout(() => {
          if (playerActions['Dance']) fadeAction(playerActions, playerActiveAction, 'Dance', 0.2, act => playerActiveAction = act);
          showVictory(true);
        }, 900);
      }
    }

    function enemyPunch() {
      if (isEnemyDead || isPlayerDead || !enemyActions['Punch']) return;
      sfxPunch();
      fadeAction(enemyActions, enemyActiveAction, 'Punch', 0.12, act => enemyActiveAction = act);
      setTimeout(() => {
        if (!isEnemyDead) fadeAction(enemyActions, enemyActiveAction, 'Idle', 0.2, act => enemyActiveAction = act);
      }, 900);

      const dx = playerModel.position.x - enemyModel.position.x;
      const dy = playerModel.position.y - enemyModel.position.y;
      const dz = playerModel.position.z - enemyModel.position.z;
      const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);

      if (dist < 2.5 && Math.abs(dy) < 1.4) {
        playerHP = Math.max(0, playerHP - 16);
        updateHUD();
        spawnPopup(playerModel.position, '-16 HP');

        const hDist = Math.sqrt(dx * dx + dz * dz) || 1;
        playerKnockback.vx = (dx / hDist) * 11.0;
        playerKnockback.vz = (dz / hDist) * 11.0;
        playerKnockback.vy = 3.8;
        cameraShake = 0.32;

        spawnSparks(playerModel.position.clone().add(new THREE.Vector3(0, 1.2, 0)), 0x00e5ff);
        flashMesh(playerModel);

        if (playerHP <= 0) {
          isPlayerDead = true;
          fadeAction(playerActions, playerActiveAction, 'Death', 0.2, act => playerActiveAction = act);
          fadeAction(enemyActions, enemyActiveAction, 'Dance', 0.2, act => enemyActiveAction = act);
          setTimeout(() => showVictory(false), 900);
        }
      }
    }

    function explodeBarrel(obs) {
      sfxExplosion();
      const bPos = obs.mesh.position.clone();
      scene.remove(obs.mesh);
      obs.mesh.geometry.dispose();
      const idx = solidObstacles.indexOf(obs);
      if (idx !== -1) solidObstacles.splice(idx, 1);

      cameraShake = 0.6;
      spawnExplosion(bPos, 0xff3300, 45);
      spawnPopup(bPos, 'BOOM! NỔ TUNG');

      const r = 7.0;
      const pd = playerModel.position.distanceTo(bPos);
      if (pd < r) {
        playerHP = Math.max(0, playerHP - 15);
        updateHUD();
        const dir = playerModel.position.clone().sub(bPos).normalize();
        playerKnockback.vx = dir.x * 16; playerKnockback.vz = dir.z * 16; playerKnockback.vy = 5;
      }
      const ed = enemyModel.position.distanceTo(bPos);
      if (ed < r) {
        enemyHP = Math.max(0, enemyHP - 25);
        updateHUD();
        const dir = enemyModel.position.clone().sub(bPos).normalize();
        enemyKnockback.vx = dir.x * 18; enemyKnockback.vz = dir.z * 18; enemyKnockback.vy = 5.5;
        if (enemyHP <= 0) {
          isEnemyDead = true;
          fadeAction(enemyActions, enemyActiveAction, 'Death', 0.2, act => enemyActiveAction = act);
          showVictory(true);
        }
      }
    }

    function addEnergy(amount) {
      playerEnergy = Math.max(0, Math.min(100, playerEnergy + amount));
      updateHUD();
      const ultBtn = document.getElementById('btn-ultimate');
      if (playerEnergy >= 100) ultBtn.classList.add('ready');
      else ultBtn.classList.remove('ready');
    }

    function updateHUD() {
      const pPercent = (playerHP / PLAYER_CONFIG.maxHp) * 100;
      document.getElementById('player-hp-num').innerText = Math.round(playerHP) + ' HP';
      document.getElementById('enemy-hp-num').innerText = Math.round(enemyHP) + ' HP';
      document.getElementById('player-hp-fill').style.width = pPercent + '%';
      document.getElementById('enemy-hp-fill').style.width = enemyHP + '%';
      document.getElementById('player-energy-fill').style.width = playerEnergy + '%';
    }

    function flashMesh(model) {
      if (!model) return;
      model.traverse(o => {
        if (o.isMesh && o.material && o.material.color) {
          const orig = o.material.color.getHex();
          o.material.color.setHex(0xffffff);
          setTimeout(() => o.material.color.setHex(orig), 100);
        }
      });
    }

    function showVictory(isWin) {
      const modal = document.getElementById('victory-modal');
      const title = document.getElementById('victory-title');
      const desc = document.getElementById('victory-desc');
      modal.style.display = 'flex';
      if (isWin) {
        title.innerText = 'CHIẾN THẮNG TUYỆT ĐỐI!';
        title.style.color = '#00e5ff';
        desc.innerText = 'Bạn đã hạ gục Mecha địch và làm chủ Đấu Trường 3D!';
      } else {
        title.innerText = 'THẤT BẠI!';
        title.style.color = '#ef4444';
        desc.innerText = 'Bạn đã bị Mecha đối thủ đánh bại. Hãy thử lại!';
      }
    }

    function resetBattle() {
      document.getElementById('victory-modal').style.display = 'none';
      playerHP = PLAYER_CONFIG.maxHp;
      enemyHP = 100;
      playerEnergy = 35;
      isPlayerDead = false;
      isEnemyDead = false;
      comboCount = 0;
      updateHUD();

      if (playerModel) {
        playerModel.position.set(0, 0, 0);
        playerModel.rotation.set(0, 0, 0);
        fadeAction(playerActions, playerActiveAction, 'Idle', 0.2, act => playerActiveAction = act);
      }
      if (enemyModel) {
        enemyModel.position.set(0, 0, 5.5);
        enemyModel.rotation.set(0, 0, 0);
        fadeAction(enemyActions, enemyActiveAction, 'Idle', 0.2, act => enemyActiveAction = act);
      }
    }

    function toggleAI() {
      enemyAIMode = !enemyAIMode;
      spawnPopup(enemyModel.position, enemyAIMode ? 'AI: BẬT' : 'AI: TẮT');
    }

    function zoomCam(delta) {
      camDistance = Math.max(3.5, Math.min(25.0, camDistance + delta));
    }
    function resetCamView() {
      camDistance = 9.0;
      camAngle = 0.0;
      camPitch = 0.38;
    }

    // ==========================================
    // 7. HIỆU ỨNG HẠT PARTICLE & POPUP CHỮ
    // ==========================================
    function spawnSparks(pos, colorHex, count = 18) {
      const geom = new THREE.BufferGeometry();
      const positions = new Float32Array(count * 3);
      const velocities = [];
      for (let i = 0; i < count; i++) {
        positions[i * 3] = pos.x;
        positions[i * 3 + 1] = pos.y;
        positions[i * 3 + 2] = pos.z;
        const th = Math.random() * Math.PI * 2;
        const ph = (Math.random() - 0.5) * Math.PI;
        const sp = 4.0 + Math.random() * 6.0;
        velocities.push(new THREE.Vector3(Math.cos(th) * Math.cos(ph) * sp, Math.sin(ph) * sp + 2.5, Math.sin(th) * Math.cos(ph) * sp));
      }
      geom.setAttribute('position', new THREE.BufferAttribute(positions, 3));
      const mat = new THREE.PointsMaterial({ color: colorHex, size: 0.22, transparent: true, blending: THREE.AdditiveBlending });
      const pts = new THREE.Points(geom, mat);
      scene.add(pts);
      particles.push({ points: pts, velocities: velocities, life: 0.35, maxLife: 0.35 });
    }

    function spawnExplosion(pos, colorHex, count = 40) {
      const geom = new THREE.BufferGeometry();
      const positions = new Float32Array(count * 3);
      const velocities = [];
      for (let i = 0; i < count; i++) {
        positions[i * 3] = pos.x;
        positions[i * 3 + 1] = pos.y + 0.5;
        positions[i * 3 + 2] = pos.z;
        const th = Math.random() * Math.PI * 2;
        const ph = (Math.random() - 0.5) * Math.PI;
        const sp = 6.0 + Math.random() * 9.0;
        velocities.push(new THREE.Vector3(Math.cos(th) * Math.cos(ph) * sp, Math.sin(ph) * sp + 3.0, Math.sin(th) * Math.cos(ph) * sp));
      }
      geom.setAttribute('position', new THREE.BufferAttribute(positions, 3));
      const mat = new THREE.PointsMaterial({ color: colorHex, size: 0.38, transparent: true, blending: THREE.AdditiveBlending });
      const pts = new THREE.Points(geom, mat);
      scene.add(pts);
      particles.push({ points: pts, velocities: velocities, life: 0.55, maxLife: 0.55 });
    }

    function spawnPopup(worldPos, text) {
      const p = worldPos.clone().add(new THREE.Vector3(0, 1.8, 0));
      p.project(camera);
      const sx = (p.x * 0.5 + 0.5) * window.innerWidth;
      const sy = (-(p.y * 0.5) + 0.5) * window.innerHeight;
      const el = document.createElement('div');
      el.className = 'damage-text';
      el.innerText = text;
      el.style.left = sx + 'px';
      el.style.top = sy + 'px';
      document.body.appendChild(el);
      setTimeout(() => el.remove(), 750);
    }

    function spawnComboPopup(worldPos, text) {
      const p = worldPos.clone().add(new THREE.Vector3(0, 2.3, 0));
      p.project(camera);
      const sx = (p.x * 0.5 + 0.5) * window.innerWidth;
      const sy = (-(p.y * 0.5) + 0.5) * window.innerHeight;
      const el = document.createElement('div');
      el.className = 'combo-text';
      el.innerText = text;
      el.style.left = sx + 'px';
      el.style.top = sy + 'px';
      document.body.appendChild(el);
      setTimeout(() => el.remove(), 850);
    }

    function fadeAction(actions, active, name, duration, setCallback) {
      if (!actions[name]) return;
      const next = actions[name];
      if (active !== next && active) {
        active.fadeOut(duration);
        next.reset().fadeIn(duration).play();
        setCallback(next);
      }
    }

    // ==========================================
    // 8. ĐIỀU KHIỂN CẢM ỨNG ĐA ĐIỂM JOYSTICK & CAMERA
    // ==========================================
    let joyForward = 0, joyRight = 0;

    function setupTouchControls() {
      const zone = document.getElementById('joystick-zone');
      const knob = document.getElementById('joystick-knob');
      let joyTouchId = null;
      let startX = 0, startY = 0;

      zone.addEventListener('touchstart', (e) => {
        e.stopPropagation();
        const t = e.changedTouches[0];
        joyTouchId = t.identifier;
        const rect = zone.getBoundingClientRect();
        startX = rect.left + rect.width / 2;
        startY = rect.top + rect.height / 2;
        updateKnob(t.clientX, t.clientY);
      }, { passive: false });

      window.addEventListener('touchmove', (e) => {
        for (let i = 0; i < e.changedTouches.length; i++) {
          const t = e.changedTouches[i];
          if (t.identifier === joyTouchId) updateKnob(t.clientX, t.clientY);
        }
      });

      function endJoy(e) {
        for (let i = 0; i < e.changedTouches.length; i++) {
          if (e.changedTouches[i].identifier === joyTouchId) {
            joyTouchId = null;
            joyForward = 0; joyRight = 0;
            knob.style.transform = 'translate(0px, 0px)';
            isMoving = false;
            if (isGrounded && !isPlayerDead) fadeAction(playerActions, playerActiveAction, 'Idle', 0.2, act => playerActiveAction = act);
          }
        }
      }
      window.addEventListener('touchend', endJoy);
      window.addEventListener('touchcancel', endJoy);

      function updateKnob(cx, cy) {
        let dx = cx - startX, dy = cy - startY;
        const maxR = 46;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist > maxR) { dx = (dx / dist) * maxR; dy = (dy / dist) * maxR; }
        knob.style.transform = `translate(\${dx}px, \${dy}px)`;
        joyForward = -dy / maxR;
        joyRight = dx / maxR;

        if (dist > 6 && !isPlayerDead) {
          if (!isMoving) {
            isMoving = true;
            fadeAction(playerActions, playerActiveAction, dist > 34 && playerActions['Running'] ? 'Running' : 'Walking', 0.2, act => playerActiveAction = act);
          }
        } else {
          isMoving = false;
          if (!isPlayerDead && isGrounded) fadeAction(playerActions, playerActiveAction, 'Idle', 0.2, act => playerActiveAction = act);
        }
      }

      // Nút bấm chiêu
      document.getElementById('btn-jump').addEventListener('click', doJump);
      document.getElementById('btn-punch').addEventListener('click', doPunch);
      document.getElementById('btn-dash').addEventListener('click', doDash);
      document.getElementById('btn-ultimate').addEventListener('click', doUltimate);

      // Camera xoay quanh
      let camTouchId = null, lastCamX = 0, lastCamY = 0;
      window.addEventListener('touchstart', (e) => {
        if (e.target.closest('#actions-container, #joystick-zone, #sub-tools, #top-hud, #map-bar')) return;
        if (e.touches.length === 1 && camTouchId === null) {
          const t = e.touches[0];
          if (t.identifier !== joyTouchId) {
            camTouchId = t.identifier;
            lastCamX = t.clientX;
            lastCamY = t.clientY;
          }
        }
      }, { passive: true });

      window.addEventListener('touchmove', (e) => {
        for (let i = 0; i < e.changedTouches.length; i++) {
          const t = e.changedTouches[i];
          if (t.identifier === camTouchId) {
            camAngle += (t.clientX - lastCamX) * 0.0075;
            camPitch = Math.max(0.08, Math.min(1.2, camPitch - (t.clientY - lastCamY) * 0.0055));
            lastCamX = t.clientX;
            lastCamY = t.clientY;
          }
        }
      }, { passive: true });

      window.addEventListener('touchend', (e) => {
        for (let i = 0; i < e.changedTouches.length; i++) {
          if (e.changedTouches[i].identifier === camTouchId) camTouchId = null;
        }
      });
    }

    function onResize() {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    }

    // ==========================================
    // 9. GAME LOOP ANIMATION
    // ==========================================
    let enemyAttackCd = 0;

    function animate() {
      requestAnimationFrame(animate);
      const dt = Math.min(clock.getDelta(), 0.1);

      if (playerMixer) playerMixer.update(dt);
      if (enemyMixer) enemyMixer.update(dt);

      if (comboTimer > 0) {
        comboTimer -= dt;
        if (comboTimer <= 0) comboCount = 0;
      }

      // Xử lý hạt particle
      for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.life -= dt;
        if (p.life <= 0) {
          scene.remove(p.points);
          p.points.geometry.dispose();
          p.points.material.dispose();
          particles.splice(i, 1);
        } else {
          const arr = p.points.geometry.attributes.position.array;
          for (let j = 0; j < p.velocities.length; j++) {
            arr[j * 3] += p.velocities[j].x * dt;
            arr[j * 3 + 1] += p.velocities[j].y * dt;
            arr[j * 3 + 2] += p.velocities[j].z * dt;
            p.velocities[j].y -= 12.0 * dt;
          }
          p.points.geometry.attributes.position.needsUpdate = true;
          p.points.material.opacity = p.life / p.maxLife;
        }
      }

      // Di chuyển Player bằng Joystick
      if (playerModel && isMoving && !isPlayerDead) {
        const spd = PLAYER_CONFIG.baseSpeed * dt;
        const mx = Math.sin(camAngle) * joyForward - Math.cos(camAngle) * joyRight;
        const mz = Math.cos(camAngle) * joyForward + Math.sin(camAngle) * joyRight;
        if (Math.abs(mx) > 0.001 || Math.abs(mz) > 0.001) {
          playerModel.rotation.y = Math.atan2(mx, mz);
          playerModel.position.x += mx * spd;
          playerModel.position.z += mz * spd;
        }
      }

      // Bệ phóng Jump Pad
      if (playerModel && isGrounded) {
        jumpPads.forEach(pad => {
          const d = Math.sqrt((playerModel.position.x - pad.x)**2 + (playerModel.position.z - pad.z)**2);
          if (d < 1.4) {
            sfxJump();
            verticalVelocity = 14.5;
            isGrounded = false;
            fadeAction(playerActions, playerActiveAction, 'Jump', 0.1, act => playerActiveAction = act);
            spawnPopup(pad.mesh.position, 'SIÊU PHÓNG CAO!');
          }
        });
      }

      // Raycasting trọng lực & Chống rơi vực
      if (playerModel) {
        const gY = getGroundHeightAt(playerModel.position.x, playerModel.position.z, playerModel.position.y);
        if (isGrounded) {
          if (playerModel.position.y > gY + 0.15) { isGrounded = false; verticalVelocity = 0; }
          else playerModel.position.y += (gY - playerModel.position.y) * 0.4;
        }
        if (!isGrounded) {
          verticalVelocity -= gravity * dt;
          playerModel.position.y += verticalVelocity * dt;
          if (playerModel.position.y <= gY) {
            playerModel.position.y = gY;
            verticalVelocity = 0;
            isGrounded = true;
            if (!isPlayerDead) fadeAction(playerActions, playerActiveAction, isMoving ? 'Walking' : 'Idle', 0.15, act => playerActiveAction = act);
          }
        }

        // CHỐNG RƠI VỰC VÔ TẬN (VOID FALL RESCUE)
        if (playerModel.position.y < -12) {
          playerModel.position.set(0, 4, 0);
          verticalVelocity = 0;
          playerHP = Math.max(1, playerHP - 10);
          updateHUD();
          spawnPopup(new THREE.Vector3(0, 2, 0), 'QUANTUM WARP HỒI SINH!');
        }

        resolveCollisions(playerModel);
      }

      // Xung lực Knockback
      if (playerModel && (Math.abs(playerKnockback.vx) > 0.01 || Math.abs(playerKnockback.vz) > 0.01 || playerKnockback.vy > 0.01)) {
        playerModel.position.x += playerKnockback.vx * dt;
        playerModel.position.z += playerKnockback.vz * dt;
        playerKnockback.vx *= 0.88; playerKnockback.vz *= 0.88;
        if (playerKnockback.vy > 0) {
          playerModel.position.y += playerKnockback.vy * dt;
          playerKnockback.vy -= gravity * dt;
        }
      }

      if (enemyModel && (Math.abs(enemyKnockback.vx) > 0.01 || Math.abs(enemyKnockback.vz) > 0.01 || enemyKnockback.vy > 0.01)) {
        enemyModel.position.x += enemyKnockback.vx * dt;
        enemyModel.position.z += enemyKnockback.vz * dt;
        enemyKnockback.vx *= 0.88; enemyKnockback.vz *= 0.88;
        if (enemyKnockback.vy > 0) {
          enemyModel.position.y += enemyKnockback.vy * dt;
          enemyKnockback.vy -= gravity * dt;
        }
      }

      // Đồ vật vật lý chuyển động
      solidObstacles.forEach(obs => {
        if (!obs.isDynamic) return;
        if (Math.abs(obs.vx) > 0.01 || Math.abs(obs.vz) > 0.01 || obs.vy !== 0) {
          obs.mesh.position.x += obs.vx * dt;
          obs.mesh.position.z += obs.vz * dt;
          obs.vx *= 0.91; obs.vz *= 0.91;
          if (obs.type === 'box' && obs.vy !== 0) {
            obs.mesh.position.y += obs.vy * dt;
            obs.vy -= gravity * dt;
            if (obs.mesh.position.y <= obs.defaultY) { obs.mesh.position.y = obs.defaultY; obs.vy = 0; }
          }
        }
      });

      // AI ĐỐI THỦ THÔNG MINH
      if (playerModel && enemyModel && !isEnemyDead && !isPlayerDead) {
        const edx = playerModel.position.x - enemyModel.position.x;
        const edz = playerModel.position.z - enemyModel.position.z;
        const dist2D = Math.sqrt(edx * edx + edz * edz);

        const egY = getGroundHeightAt(enemyModel.position.x, enemyModel.position.z, enemyModel.position.y);
        if (enemyGrounded) {
          if (enemyModel.position.y > egY + 0.15) { enemyGrounded = false; enemyVerticalVelocity = 0; }
          else enemyModel.position.y += (egY - enemyModel.position.y) * 0.4;
        }
        if (!enemyGrounded) {
          enemyVerticalVelocity -= gravity * dt;
          enemyModel.position.y += enemyVerticalVelocity * dt;
          if (enemyModel.position.y <= egY) {
            enemyModel.position.y = egY;
            enemyVerticalVelocity = 0;
            enemyGrounded = true;
          }
        }

        if (enemyModel.position.y < -12) {
          enemyModel.position.set(0, 4, 5);
          enemyVerticalVelocity = 0;
        }

        resolveCollisions(enemyModel);

        if (enemyAIMode) {
          enemyModel.rotation.y = Math.atan2(edx, edz);
          if (dist2D > 2.2) {
            const eSpeed = 2.6 * dt;
            enemyModel.position.x += (edx / dist2D) * eSpeed;
            enemyModel.position.z += (edz / dist2D) * eSpeed;
            if (enemyActiveAction && enemyActiveAction.getClip().name !== 'Walking') {
              fadeAction(enemyActions, enemyActiveAction, 'Walking', 0.2, act => enemyActiveAction = act);
            }
          } else {
            if (enemyAttackCd <= 0) {
              enemyAttackCd = 1.6;
              enemyPunch();
            }
          }
        }
        if (enemyAttackCd > 0) enemyAttackCd -= dt;
      }

      // Camera theo sau Player mượt mà + Rung lắc
      if (playerModel) {
        let sx = 0, sy = 0;
        if (cameraShake > 0.005) {
          sx = (Math.random() - 0.5) * cameraShake * 1.8;
          sy = (Math.random() - 0.5) * cameraShake * 1.8;
          cameraShake *= 0.86;
        }
        const tx = playerModel.position.x - Math.sin(camAngle) * camDistance * Math.cos(camPitch) + sx;
        const tz = playerModel.position.z - Math.cos(camAngle) * camDistance * Math.cos(camPitch);
        const ty = Math.max(0.6, playerModel.position.y + Math.sin(camPitch) * camDistance + 1.5 + sy);

        camera.position.x += (tx - camera.position.x) * 0.12;
        camera.position.y += (ty - camera.position.y) * 0.12;
        camera.position.z += (tz - camera.position.z) * 0.12;
        camera.lookAt(playerModel.position.x, playerModel.position.y + 1.25, playerModel.position.z);
      }

      renderer.render(scene, camera);
    }
  </script>
</body>
</html>
''';
  }
}
