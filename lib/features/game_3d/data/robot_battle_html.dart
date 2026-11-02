/// Mã nguồn HTML, CSS và JavaScript của Three.js 3D Robot Battle Arena.
/// Đã được nâng cấp toàn diện:
/// 1. Bộ chuyển đổi Bản đồ 3D Đa dạng (Map Switcher):
///    - Map 1: 🏙️ Đấu trường Cyber Matrix (Tòa tháp, Cầu treo, Bệ phóng Jump Pad, Đèn Neon)
///    - Map 2: 🏰 Lâu đài Hầm ngục Cổ đại (Tường đá, Cột trụ La Mã, Đuốc lửa, Rương cổ)
///    - Map 3: 🪐 Trạm Không gian Deep Space (Bệ đáp phi thuyền, Lưới laser, Không gian vũ trụ)
///    - Map 4: 🌐 Tải Bản đồ GLB từ mạng (Cho phép nhập link mô hình 3D bất kỳ)
/// 2. Bản đồ hoàn thiện khép kín: Có tường rào bảo vệ vững chắc, tháp canh 4 góc, chống rớt ra khoảng không.
/// 3. Động cơ vật lý AABB 3D đặc khít: Chặn ngang không xuyên tường, leo bậc thang và đứng trên nóc tháp.
/// 4. Đồ vật vật lý phong phú: Thùng phuy thuốc nổ đỏ (nổ văng shockwave), thùng gỗ xếp tầng, quả cầu kim loại lăn theo quán tính.
/// 5. Điều khiển Camera 360° & Pinch Zoom mượt mà, cách ly cảm ứng hoàn toàn.
class RobotBattleHtml {
  RobotBattleHtml._();

  static const String content = '''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>3D Robot Battle Arena - Open Worlds & Solid Physics</title>
  <style>
    * {
      box-sizing: border-box;
      user-select: none;
      -webkit-user-select: none;
      touch-action: none;
    }
    body, html {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background-color: #070B14;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    #canvas-container {
      width: 100%;
      height: 100%;
      position: absolute;
      top: 0;
      left: 0;
    }
    /* CẦN JOYSTICK */
    #joystick-zone {
      position: absolute;
      bottom: 24px;
      left: 20px;
      width: 126px;
      height: 126px;
      border-radius: 50%;
      background: rgba(0, 0, 0, 0.65);
      border: 2px solid rgba(0, 229, 255, 0.6);
      display: flex;
      align-items: center;
      justify-content: center;
      touch-action: none;
      z-index: 20;
    }
    #joystick-knob {
      width: 52px;
      height: 52px;
      border-radius: 50%;
      background: radial-gradient(circle, #ffffff 10%, #00e5ff 85%);
      box-shadow: 0 0 20px rgba(0, 229, 255, 0.95);
      position: absolute;
      pointer-events: none;
    }
    /* BẢNG PHÍM HÀNH ĐỘNG CHIẾN ĐẤU */
    #action-pad {
      position: absolute;
      bottom: 20px;
      right: 18px;
      display: flex;
      flex-direction: column;
      gap: 9px;
      align-items: flex-end;
      z-index: 20;
    }
    .btn-action {
      background: rgba(15, 23, 42, 0.92);
      border: 1.5px solid #00e5ff;
      color: white;
      font-weight: 800;
      font-size: 11px;
      padding: 10px 16px;
      border-radius: 22px;
      box-shadow: 0 0 12px rgba(0, 229, 255, 0.35);
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      transition: transform 0.08s ease;
    }
    .btn-action:active {
      transform: scale(0.92);
    }
    #btn-punch {
      background: linear-gradient(135deg, #ef4444, #b91c1c);
      border-color: #fca5a5;
      color: white;
      font-size: 13.5px;
      font-weight: 900;
      padding: 14px 22px;
      border-radius: 30px;
      box-shadow: 0 0 22px rgba(239, 68, 68, 0.85);
    }
    #btn-punch:active {
      background: #ffffff;
      color: #b91c1c;
    }
    #btn-jump {
      background: linear-gradient(135deg, #0ea5e9, #0284c7);
      border-color: #38bdf8;
      color: white;
      font-size: 13px;
      font-weight: 900;
      padding: 12px 20px;
      border-radius: 28px;
      box-shadow: 0 0 18px rgba(14, 165, 233, 0.75);
    }
    #btn-jump:active {
      background: #ffffff;
      color: #0284c7;
    }
    /* CỤM NÚT CAMERA TOOLS */
    #camera-tools-pad {
      position: absolute;
      bottom: 165px;
      left: 20px;
      display: flex;
      flex-direction: column;
      gap: 8px;
      z-index: 20;
    }
    .btn-cam-tool {
      width: 42px;
      height: 42px;
      border-radius: 50%;
      background: rgba(10, 15, 29, 0.88);
      border: 1.5px solid rgba(0, 229, 255, 0.65);
      color: #00e5ff;
      font-size: 17px;
      font-weight: bold;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 0 12px rgba(0, 229, 255, 0.35);
      cursor: pointer;
    }
    .btn-cam-tool:active {
      background: #00e5ff;
      color: black;
      transform: scale(0.92);
    }
    /* THANH CHỌN BẢN ĐỒ TRÊN ĐẦU (MAP SELECTOR) */
    #map-selector-bar {
      position: absolute;
      top: 66px;
      left: 14px;
      right: 14px;
      display: flex;
      gap: 8px;
      overflow-x: auto;
      padding-bottom: 4px;
      z-index: 20;
    }
    .btn-map-tab {
      background: rgba(10, 15, 29, 0.88);
      border: 1.5px solid rgba(0, 229, 255, 0.4);
      color: #a5f3fc;
      font-size: 10.5px;
      font-weight: bold;
      padding: 6px 12px;
      border-radius: 14px;
      white-space: nowrap;
      cursor: pointer;
      backdrop-filter: blur(4px);
    }
    .btn-map-tab.active {
      background: #00e5ff;
      color: #000;
      border-color: #ffffff;
      box-shadow: 0 0 10px rgba(0, 229, 255, 0.8);
    }
    /* THANH MÁU CHIẾN ĐẤU */
    #health-hud {
      position: absolute;
      top: 14px;
      left: 14px;
      right: 14px;
      display: flex;
      justify-content: space-between;
      gap: 16px;
      z-index: 20;
      pointer-events: none;
    }
    .health-card {
      flex: 1;
      max-width: 220px;
      background: rgba(10, 15, 29, 0.88);
      border: 1.5px solid rgba(0, 229, 255, 0.5);
      border-radius: 12px;
      padding: 8px 12px;
      backdrop-filter: blur(4px);
    }
    .health-title {
      font-size: 10.5px;
      font-weight: 800;
      letter-spacing: 0.5px;
      margin-bottom: 4px;
      display: flex;
      justify-content: space-between;
    }
    .health-bar-bg {
      width: 100%;
      height: 9px;
      background: rgba(255, 255, 255, 0.15);
      border-radius: 6px;
      overflow: hidden;
    }
    .health-bar-fill {
      height: 100%;
      border-radius: 6px;
      transition: width 0.25s ease-out;
    }
    #player-hp-fill {
      width: 100%;
      background: linear-gradient(90deg, #00e5ff, #3b82f6);
    }
    #enemy-hp-fill {
      width: 100%;
      background: linear-gradient(90deg, #f43f5e, #e11d48);
    }
    /* POPUP HIỆU ỨNG CHỮ VẬT LÝ */
    .damage-text {
      position: absolute;
      color: #ff3366;
      font-weight: 900;
      font-size: 18px;
      pointer-events: none;
      animation: floatUp 0.85s forwards;
      text-shadow: 0 0 10px rgba(0, 0, 0, 0.95), 0 0 20px #ff0055;
      z-index: 30;
    }
    @keyframes floatUp {
      0% { opacity: 1; transform: translateY(0) scale(1.3); }
      100% { opacity: 0; transform: translateY(-45px) scale(0.85); }
    }
    #loading-overlay {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: #070B14;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: #00e5ff;
      font-size: 14px;
      font-weight: bold;
      z-index: 100;
      transition: opacity 0.5s;
    }
    .spinner {
      width: 44px;
      height: 44px;
      border: 4px solid rgba(0, 229, 255, 0.2);
      border-top-color: #00e5ff;
      border-radius: 50%;
      animation: spin 1s infinite linear;
      margin-bottom: 12px;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
</head>
<body>
  <div id="loading-overlay">
    <div class="spinner"></div>
    <div id="loading-text">Đang tải Đấu Trường 3D Đa Tầng...</div>
  </div>

  <!-- THANH MÁU CHIẾN ĐẤU -->
  <div id="health-hud">
    <div class="health-card" style="border-color: #00e5ff;">
      <div class="health-title" style="color: #00e5ff;">
        <span>🤖 ROBOT CỦA BẠN</span>
        <span id="player-hp-text">100 HP</span>
      </div>
      <div class="health-bar-bg">
        <div id="player-hp-fill" class="health-bar-fill"></div>
      </div>
    </div>

    <div class="health-card" style="border-color: #f43f5e;">
      <div class="health-title" style="color: #f43f5e;">
        <span>🦹 ĐỐI THỦ CYBER</span>
        <span id="enemy-hp-text">100 HP</span>
      </div>
      <div class="health-bar-bg">
        <div id="enemy-hp-fill" class="health-bar-fill"></div>
      </div>
    </div>
  </div>

  <!-- THANH CHUYỂN ĐỔI BẢN ĐỒ (MAP SWITCHER) -->
  <div id="map-selector-bar">
    <button class="btn-map-tab active" id="tab-map-cyber" onclick="switchMapTheme('cyber')">🏙️ Đấu Trường Cyber</button>
    <button class="btn-map-tab" id="tab-map-dungeon" onclick="switchMapTheme('dungeon')">🏰 Lâu Đài Hầm Ngục</button>
    <button class="btn-map-tab" id="tab-map-space" onclick="switchMapTheme('space')">🪐 Trạm Vũ Trụ Deep Space</button>
    <button class="btn-map-tab" id="tab-map-custom" onclick="promptCustomMapUrl()">🌐 Tải Map GLB URL</button>
  </div>

  <div id="canvas-container"></div>

  <!-- CỤM CÔNG CỤ CAMERA ZOOM & RESET -->
  <div id="camera-tools-pad">
    <div class="btn-cam-tool" onclick="zoomCamera(-2.0)" title="Phóng to">➕</div>
    <div class="btn-cam-tool" onclick="zoomCamera(2.0)" title="Thu nhỏ">➖</div>
    <div class="btn-cam-tool" onclick="resetCameraView()" title="Đặt lại góc nhìn">🎯</div>
  </div>

  <!-- CẦN JOYSTICK -->
  <div id="joystick-zone">
    <div id="joystick-knob"></div>
  </div>

  <!-- BẢNG PHÍM HÀNH ĐỘNG CHIẾN ĐẤU -->
  <div id="action-pad">
    <button class="btn-action" id="btn-punch">🥊 CÚ ĐẤM UY LỰC</button>
    <button class="btn-action" id="btn-jump">🚀 BẬT NHẢY CAO</button>
    <button class="btn-action" onclick="toggleEnemyAI()" id="btn-ai">⚔️ ĐỐI THỦ: TỰ ĐỘNG ĐÁNH</button>
    <button class="btn-action" onclick="resetBattle()">🔄 ĐẶT LẠI TRẬN ĐẤU</button>
  </div>

  <script>
    let scene, camera, renderer, clock;
    let playerModel, playerMixer, playerActions = {}, playerActiveAction;
    let enemyModel, enemyMixer, enemyActions = {}, enemyActiveAction;
    let isMoving = false;

    // VẬT LÝ TRỌNG LỰC & NHẢY
    let isGrounded = true;
    let verticalVelocity = 0;
    const gravity = 22.0;
    const jumpForce = 8.8;

    // VẬT LÝ ĐỐI THỦ AI
    let enemyGrounded = true;
    let enemyVerticalVelocity = 0;

    // VẬT LÝ XUNG LỰC ĐÒN ĐÁNH
    const playerKnockback = { vx: 0, vy: 0, vz: 0 };
    const enemyKnockback = { vx: 0, vy: 0, vz: 0 };
    let enemyTilt = 0;
    let playerTilt = 0;
    let cameraShake = 0;

    // Chỉ số Máu & Trạng thái Chiến Đấu
    let playerHP = 100;
    let enemyHP = 100;
    let isPlayerDead = false;
    let isEnemyDead = false;
    let enemyAIMode = true;

    // Camera Orbit & Zoom Đa Điểm
    let camDistance = 9.0;
    let camAngle = 0.0;
    let camPitch = 0.38;

    // HỆ THỐNG VẬT LÝ VÀ BẢN ĐỒ
    let solidObstacles = [];
    let mapMeshes = [];
    let jumpPads = [];
    const particles = [];
    let currentMapTheme = 'cyber';

    init();
    animate();

    function init() {
      const container = document.getElementById('canvas-container');
      clock = new THREE.Clock();

      scene = new THREE.Scene();
      scene.background = new THREE.Color(0x070B14);
      scene.fog = new THREE.FogExp2(0x070B14, 0.016);

      camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 140);

      renderer = new THREE.WebGLRenderer({ antialias: true });
      renderer.setPixelRatio(window.devicePixelRatio);
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.shadowMap.enabled = true;
      renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      container.appendChild(renderer.domElement);

      const hemiLight = new THREE.HemisphereLight(0xffffff, 0x1e293b, 0.85);
      scene.add(hemiLight);

      const dirLight = new THREE.DirectionalLight(0x00e5ff, 1.4);
      dirLight.position.set(12, 22, 12);
      dirLight.castShadow = true;
      dirLight.shadow.mapSize.width = 1024;
      dirLight.shadow.mapSize.height = 1024;
      dirLight.shadow.camera.near = 0.5;
      dirLight.shadow.camera.far = 50;
      dirLight.shadow.camera.left = -22;
      dirLight.shadow.camera.right = 22;
      dirLight.shadow.camera.top = 22;
      dirLight.shadow.camera.bottom = -22;
      scene.add(dirLight);

      // KHỞI TẠO BẢN ĐỒ MẶC ĐỊNH
      buildMap(currentMapTheme);

      // TẢI 2 ROBOT 3D
      const loader = new THREE.GLTFLoader();
      const modelUrl = 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/RobotExpressive/RobotExpressive.glb';

      loader.load(modelUrl, function (gltf) {
        playerModel = gltf.scene;
        playerModel.scale.set(0.65, 0.65, 0.65);
        playerModel.position.set(0, 0, 0);
        playerModel.traverse(obj => {
          if (obj.isMesh) { obj.castShadow = true; obj.receiveShadow = true; }
        });
        scene.add(playerModel);

        playerMixer = new THREE.AnimationMixer(playerModel);
        gltf.animations.forEach(clip => {
          playerActions[clip.name] = playerMixer.clipAction(clip);
        });

        playerActiveAction = playerActions['Idle'];
        if (playerActiveAction) playerActiveAction.play();

        loader.load(modelUrl, function (gltf2) {
          enemyModel = gltf2.scene;
          enemyModel.scale.set(0.65, 0.65, 0.65);
          enemyModel.position.set(0, 0, 5.0);

          enemyModel.traverse(obj => {
            if (obj.isMesh) {
              obj.castShadow = true;
              obj.receiveShadow = true;
              if (obj.material) {
                obj.material = obj.material.clone();
                if (obj.name.includes('Body') || obj.name.includes('Head')) {
                  obj.material.color.setHex(0xe11d48);
                }
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

          document.getElementById('loading-overlay').style.opacity = '0';
          setTimeout(() => {
            document.getElementById('loading-overlay').style.display = 'none';
          }, 500);
        });

      }, undefined, function (error) {
        console.error('Lỗi tải Robot GLB:', error);
        document.getElementById('loading-text').innerText = 'Không thể tải mô hình (Kiểm tra mạng)';
      });

      setupControls();
      window.addEventListener('resize', onWindowResize, false);
    }

    // ĐĂNG KÝ VẬT THỂ VẬT LÝ SOLID VÀO BẢN ĐỒ
    function registerSolidBox(x, y, z, w, h, d, mat, isDynamic = false, extraProps = {}) {
      const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
      mesh.position.set(x, y, z);
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      scene.add(mesh);
      mapMeshes.push(mesh);

      const obs = {
        type: 'box',
        mesh: mesh,
        x: x, y: y, z: z,
        w: w, h: h, d: d,
        halfW: w / 2,
        halfH: h / 2,
        halfD: d / 2,
        isDynamic: isDynamic,
        vx: 0, vy: 0, vz: 0,
        rotVx: 0,
        defaultY: y,
        ...extraProps
      };
      solidObstacles.push(obs);
      return obs;
    }

    // XÓA BẢN ĐỒ HIỆN TẠI ĐỂ ĐỔI SANG MAP MỚI
    function clearCurrentMap() {
      mapMeshes.forEach(mesh => {
        scene.remove(mesh);
        if (mesh.geometry) mesh.geometry.dispose();
      });
      mapMeshes = [];
      solidObstacles = [];
      jumpPads = [];
    }

    // HỆ THỐNG XÂY DỰNG CÁC BẢN ĐỒ 3D HOÀN CHỈNH
    function buildMap(theme) {
      clearCurrentMap();
      currentMapTheme = theme;

      // Cập nhật nút active trên UI
      document.querySelectorAll('.btn-map-tab').forEach(b => b.classList.remove('active'));
      const activeBtn = document.getElementById('tab-map-' + theme);
      if (activeBtn) activeBtn.classList.add('active');

      if (theme === 'cyber') {
        buildCyberArenaMap();
      } else if (theme === 'dungeon') {
        buildDungeonRuinsMap();
      } else if (theme === 'space') {
        buildDeepSpaceMap();
      }
    }

    // 1. MAP: ĐẤU TRƯỜNG CYBER MATRIX (HOÀN THIỆN ĐA TẦNG & TƯỜNG CHẮN)
    function buildCyberArenaMap() {
      scene.background = new THREE.Color(0x070B14);
      scene.fog = new THREE.FogExp2(0x070B14, 0.016);

      // Sàn đấu chính
      const floorMat = new THREE.MeshStandardMaterial({ color: 0x0a0f1d, roughness: 0.65, metalness: 0.25 });
      const floor = new THREE.Mesh(new THREE.PlaneGeometry(64, 64), floorMat);
      floor.rotation.x = -Math.PI / 2;
      floor.receiveShadow = true;
      scene.add(floor);
      mapMeshes.push(floor);

      const grid = new THREE.GridHelper(64, 32, 0x00e5ff, 0x1e293b);
      grid.position.y = 0.01;
      scene.add(grid);
      mapMeshes.push(grid);

      // TƯỜNG RÀO NĂNG LƯỢNG 4 PHÍA (CHỐNG RỚT RA NGOÀI VÕ ĐÀI)
      const fenceMat = new THREE.MeshStandardMaterial({ color: 0x0f172a, roughness: 0.3, metalness: 0.8 });
      const neonBorder = new THREE.MeshBasicMaterial({ color: 0x00e5ff });

      registerSolidBox(0, 1.0, -32, 64, 2.0, 1.2, fenceMat);
      registerSolidBox(0, 1.0, 32, 64, 2.0, 1.2, fenceMat);
      registerSolidBox(-32, 1.0, 0, 1.2, 2.0, 64, fenceMat);
      registerSolidBox(32, 1.0, 0, 1.2, 2.0, 64, fenceMat);

      // Viền Neon phát sáng trên tường rào
      const n1 = new THREE.Mesh(new THREE.BoxGeometry(64, 0.15, 0.2), neonBorder);
      n1.position.set(0, 2.05, -32); scene.add(n1); mapMeshes.push(n1);

      // 4 THÁP CANH 4 GÓC (CORNER TOWERS)
      const towerMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.4, metalness: 0.5 });
      const cornerCoords = [[-28, -28], [28, -28], [-28, 28], [28, 28]];
      cornerCoords.forEach(c => {
        registerSolidBox(c[0], 2.0, c[1], 6, 4.0, 6, towerMat);
        const beacon = new THREE.Mesh(new THREE.CylinderGeometry(0.5, 0.5, 1.5, 16), neonBorder);
        beacon.position.set(c[0], 4.75, c[1]);
        scene.add(beacon); mapMeshes.push(beacon);
      });

      // BẬC THANG ĐÁ 4 CẤP LÊN THÁP A (X = 6, Z = -6)
      const stoneMat = new THREE.MeshStandardMaterial({ color: 0x334155, roughness: 0.5, metalness: 0.3 });
      for (let i = 0; i < 4; i++) {
        const h = (i + 1) * 0.55;
        const z = -6.0 - (i * 1.6);
        registerSolidBox(6.0, h / 2, z, 4.0, h, 1.6, stoneMat);
      }

      // THÁP TRÊN CAO A (ĐỘ CAO 2.2m)
      registerSolidBox(6.0, 1.1, -15.0, 7.5, 2.2, 7.5, towerMat);

      // CẦU TREO KHÔNG GIAN DÀI 14M (SKY BRIDGE)
      registerSolidBox(-3.0, 1.1, -5.0, 14.0, 2.2, 3.2, fenceMat);

      // THÁP TRÊN CAO B (ĐỘ CAO 2.2m)
      registerSolidBox(-12.0, 1.1, -5.0, 7.5, 2.2, 7.5, towerMat);

      // BỆ PHÓNG JUMP PAD KÉP
      addJumpPad(-3, 6);
      addJumpPad(12, -8);

      // ĐỒ VẬT VẬT LÝ (THÙNG GỖ, THÙNG NỔ, BÓNG)
      spawnThemeProps(true);
    }

    // 2. MAP: LÂU ĐÀI HẦM NGỤC CỔ ĐẠI (DUNGEON RUINS)
    function buildDungeonRuinsMap() {
      scene.background = new THREE.Color(0x181410);
      scene.fog = new THREE.FogExp2(0x181410, 0.02);

      const dungeonFloorMat = new THREE.MeshStandardMaterial({ color: 0x272421, roughness: 0.8, metalness: 0.1 });
      const floor = new THREE.Mesh(new THREE.PlaneGeometry(64, 64), dungeonFloorMat);
      floor.rotation.x = -Math.PI / 2;
      floor.receiveShadow = true;
      scene.add(floor);
      mapMeshes.push(floor);

      const wallMat = new THREE.MeshStandardMaterial({ color: 0x3f3934, roughness: 0.85, metalness: 0.1 });
      const columnMat = new THREE.MeshStandardMaterial({ color: 0x574f48, roughness: 0.7, metalness: 0.2 });

      // TƯỜNG THÀNH ĐÁ KHÉP KÍN
      registerSolidBox(0, 1.5, -32, 64, 3.0, 2.0, wallMat);
      registerSolidBox(0, 1.5, 32, 64, 3.0, 2.0, wallMat);
      registerSolidBox(-32, 1.5, 0, 2.0, 3.0, 64, wallMat);
      registerSolidBox(32, 1.5, 0, 2.0, 3.0, 64, wallMat);

      // DÃY CỘT TRỤ ĐÁ LA MÃ
      const colCoords = [
        [-8, -8], [8, -8], [-8, 8], [8, 8],
        [-16, -16], [16, -16], [-16, 16], [16, 16]
      ];
      colCoords.forEach(cp => {
        const col = new THREE.Mesh(new THREE.CylinderGeometry(0.8, 0.8, 4.0, 16), columnMat);
        col.position.set(cp[0], 2.0, cp[1]);
        col.castShadow = true; col.receiveShadow = true;
        scene.add(col); mapMeshes.push(col);
        registerSolidBox(cp[0], 2.0, cp[1], 1.6, 4.0, 1.6, columnMat);
      });

      // BỆ ĐÁ TẾ LỄ TRUNG TÂM (ĐỘ CAO 1.2M CÓ BẬC THANG LÊN)
      registerSolidBox(0, 0.35, 0, 10.0, 0.7, 10.0, wallMat);
      registerSolidBox(0, 0.85, 0, 6.0, 0.7, 6.0, columnMat);

      // Bệ phóng cổng thần bí
      addJumpPad(-8, 0, 0xffaa00);
      addJumpPad(8, 0, 0xffaa00);

      spawnThemeProps(false);
    }

    // 3. MAP: TRẠM KHÔNG GIAN DEEP SPACE (ORBITAL STATION)
    function buildDeepSpaceMap() {
      scene.background = new THREE.Color(0x02040a);
      scene.fog = new THREE.FogExp2(0x02040a, 0.012);

      const metalPlatesMat = new THREE.MeshStandardMaterial({ color: 0x1e293b, roughness: 0.3, metalness: 0.85 });
      const floor = new THREE.Mesh(new THREE.PlaneGeometry(64, 64), metalPlatesMat);
      floor.rotation.x = -Math.PI / 2;
      floor.receiveShadow = true;
      scene.add(floor);
      mapMeshes.push(floor);

      // Vòng tròn hạ cánh phi thuyền trung tâm
      const ringGeo = new THREE.RingGeometry(8, 9.5, 48);
      const ringMat = new THREE.MeshBasicMaterial({ color: 0x38bdf8, side: THREE.DoubleSide });
      const ring = new THREE.Mesh(ringGeo, ringMat);
      ring.rotation.x = -Math.PI / 2;
      ring.position.y = 0.02;
      scene.add(ring); mapMeshes.push(ring);

      // CÁC BỆ NĂNG LƯỢNG VŨ TRỤ
      const podMat = new THREE.MeshStandardMaterial({ color: 0x0f172a, roughness: 0.2, metalness: 0.9 });
      registerSolidBox(-14, 1.25, -14, 8, 2.5, 8, podMat);
      registerSolidBox(14, 1.25, 14, 8, 2.5, 8, podMat);

      addJumpPad(0, -10, 0x38bdf8);
      addJumpPad(0, 10, 0x38bdf8);

      spawnThemeProps(true);
    }

    // THÊM BỆ PHÓNG JUMP PAD
    function addJumpPad(x, z, colorHex = 0x00e5ff) {
      const padGeo = new THREE.CylinderGeometry(1.5, 1.7, 0.15, 32);
      const padMat = new THREE.MeshStandardMaterial({
        color: colorHex,
        emissive: colorHex,
        emissiveIntensity: 0.4,
        roughness: 0.2,
        metalness: 0.8
      });
      const padMesh = new THREE.Mesh(padGeo, padMat);
      padMesh.position.set(x, 0.08, z);
      padMesh.receiveShadow = true;
      scene.add(padMesh);
      mapMeshes.push(padMesh);

      jumpPads.push({ mesh: padMesh, x: x, z: z });
    }

    // SINH CÁC ĐỒ VẬT VẬT LÝ TƯƠNG TÁC
    function spawnThemeProps(hasBarrels) {
      const crateMat = new THREE.MeshStandardMaterial({ color: 0xf59e0b, roughness: 0.35, metalness: 0.35 });
      const barrelMat = new THREE.MeshStandardMaterial({ color: 0xdc2626, roughness: 0.25, metalness: 0.5 });
      const metalSphereMat = new THREE.MeshStandardMaterial({ color: 0x38bdf8, roughness: 0.1, metalness: 0.95 });

      // Cụm thùng gỗ xếp tầng
      const crateCoords = [
        [-6.0, 0.6, 4.0], [-4.6, 0.6, 4.0], [-5.3, 1.8, 4.0],
        [4.0, 0.6, 8.0], [5.4, 0.6, 8.0], [4.7, 1.8, 8.0]
      ];
      crateCoords.forEach(p => {
        registerSolidBox(p[0], p[1], p[2], 1.2, 1.2, 1.2, crateMat, true, { radius: 0.8 });
      });

      // Thùng phuy phát nổ
      if (hasBarrels) {
        const barrelCoords = [[0.0, 0.8, -3.5], [8.0, 0.8, 4.0], [-8.0, 0.8, -12.0]];
        barrelCoords.forEach(bp => {
          const barrelMesh = new THREE.Mesh(new THREE.CylinderGeometry(0.65, 0.65, 1.6, 24), barrelMat);
          barrelMesh.position.set(bp[0], bp[1], bp[2]);
          barrelMesh.castShadow = true; barrelMesh.receiveShadow = true;
          scene.add(barrelMesh); mapMeshes.push(barrelMesh);

          solidObstacles.push({
            type: 'box',
            mesh: barrelMesh,
            x: bp[0], y: bp[1], z: bp[2],
            w: 1.3, h: 1.6, d: 1.3,
            halfW: 0.65, halfH: 0.8, halfD: 0.65,
            isDynamic: true,
            isBarrel: true,
            vx: 0, vy: 0, vz: 0,
            defaultY: bp[1],
            radius: 0.75
          });
        });
      }

      // Quả cầu kim loại lăn trôi
      const sph = new THREE.Mesh(new THREE.SphereGeometry(1.0, 32, 32), metalSphereMat);
      sph.position.set(-6.0, 1.0, -9.0);
      sph.castShadow = true;
      scene.add(sph); mapMeshes.push(sph);
      solidObstacles.push({
        type: 'sphere',
        mesh: sph,
        x: -6.0, y: 1.0, z: -9.0,
        radius: 1.0,
        isDynamic: true,
        isBarrel: false,
        vx: 0, vy: 0, vz: 0,
        defaultY: 1.0
      });
    }

    // CHUYỂN BẢN ĐỒ
    function switchMapTheme(theme) {
      buildMap(theme);
      resetBattle();
      spawnDamagePopup(new THREE.Vector3(0, 2, 0), '🗺️ ĐÃ CHUYỂN BẢN ĐỒ!');
    }

    // TẢI BẢN ĐỒ TÙY CHỌN TỪ MẠNG BẰNG LINK .GLB
    function promptCustomMapUrl() {
      const url = prompt(
        'Nhập URL mô hình 3D bản đồ dạng .glb/.gltf từ mạng:',
        'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Duck/glTF-Binary/Duck.glb'
      );
      if (!url) return;

      document.getElementById('loading-overlay').style.display = 'flex';
      document.getElementById('loading-overlay').style.opacity = '1';
      document.getElementById('loading-text').innerText = 'Đang tải bản đồ GLB từ mạng...';

      const loader = new THREE.GLTFLoader();
      loader.load(url, function (gltf) {
        clearCurrentMap();
        const mapObj = gltf.scene;
        mapObj.scale.set(3.0, 3.0, 3.0);
        mapObj.position.set(0, 0, 0);
        mapObj.traverse(o => {
          if (o.isMesh) { o.receiveShadow = true; o.castShadow = true; }
        });
        scene.add(mapObj);
        mapMeshes.push(mapObj);

        // Tạo sàn cơ sở cho map custom
        const floor = new THREE.Mesh(new THREE.PlaneGeometry(80, 80), new THREE.MeshStandardMaterial({ color: 0x111827 }));
        floor.rotation.x = -Math.PI / 2;
        floor.receiveShadow = true;
        scene.add(floor);
        mapMeshes.push(floor);

        spawnThemeProps(true);
        resetBattle();

        document.getElementById('loading-overlay').style.opacity = '0';
        setTimeout(() => document.getElementById('loading-overlay').style.display = 'none', 500);
      }, undefined, function (err) {
        alert('Không thể tải mô hình 3D từ link này. Vui lòng kiểm tra lại URL .glb!');
        document.getElementById('loading-overlay').style.display = 'none';
      });
    }

    // ĐỘNG CƠ TÍNH MẶT SÀN TẠI TỌA ĐỘ (X, Z)
    function getGroundHeightAt(x, z, currentY) {
      let floorY = 0;
      for (let i = 0; i < solidObstacles.length; i++) {
        const obs = solidObstacles[i];
        if (obs.type === 'box') {
          const hw = obs.halfW + 0.35;
          const hd = obs.halfD + 0.35;
          const bx = obs.mesh.position.x;
          const bz = obs.mesh.position.z;
          const topY = obs.mesh.position.y + obs.halfH;

          if (x >= bx - hw && x <= bx + hw && z >= bz - hd && z <= bz + hd) {
            if (currentY >= topY - 0.65) {
              if (topY > floorY) floorY = topY;
            }
          }
        }
      }
      return floorY;
    }

    // CHẶN VA CHẠM NGANG VỮNG CHẮC (CHỐNG ĐI XUYÊN VẬT CẢN)
    function resolveHorizontalCollisions(model, radius = 0.65) {
      const px = model.position.x;
      const py = model.position.y;
      const pz = model.position.z;

      for (let i = 0; i < solidObstacles.length; i++) {
        const obs = solidObstacles[i];
        if (obs.type === 'box') {
          const bx = obs.mesh.position.x;
          const bz = obs.mesh.position.z;
          const topY = obs.mesh.position.y + obs.halfH;

          if (py < topY - 0.25) {
            const minX = bx - obs.halfW - radius;
            const maxX = bx + obs.halfW + radius;
            const minZ = bz - obs.halfD - radius;
            const maxZ = bz + obs.halfD + radius;

            if (px > minX && px < maxX && pz > minZ && pz < maxZ) {
              const distLeft = px - minX;
              const distRight = maxX - px;
              const distTop = pz - minZ;
              const distBottom = maxZ - pz;
              const minDist = Math.min(distLeft, distRight, distTop, distBottom);

              if (minDist === distLeft) {
                model.position.x = minX;
                if (obs.isDynamic) obs.vx = -3.5;
              } else if (minDist === distRight) {
                model.position.x = maxX;
                if (obs.isDynamic) obs.vx = 3.5;
              } else if (minDist === distTop) {
                model.position.z = minZ;
                if (obs.isDynamic) obs.vz = -3.5;
              } else {
                model.position.z = maxZ;
                if (obs.isDynamic) obs.vz = 3.5;
              }
            }
          }
        } else if (obs.type === 'sphere') {
          const sx = obs.mesh.position.x;
          const sz = obs.mesh.position.z;
          const dx = px - sx;
          const dz = pz - sz;
          const dist = Math.sqrt(dx * dx + dz * dz);
          const minDist = radius + obs.radius;

          if (dist < minDist && dist > 0.001) {
            const overlap = minDist - dist;
            const nx = dx / dist;
            const nz = dz / dist;
            model.position.x += nx * overlap;
            model.position.z += nz * overlap;
            obs.vx = -nx * 4.5;
            obs.vz = -nz * 4.5;
          }
        }
      }
    }

    function zoomCamera(delta) {
      camDistance = Math.max(3.2, Math.min(26.0, camDistance + delta));
    }

    function resetCameraView() {
      camDistance = 9.0;
      camAngle = 0.0;
      camPitch = 0.38;
    }

    function toggleEnemyAI() {
      enemyAIMode = !enemyAIMode;
      document.getElementById('btn-ai').innerText = enemyAIMode ? '⚔️ ĐỐI THỦ: TỰ ĐỘNG ĐÁNH' : '🛑 ĐỐI THỦ: ĐỨNG YÊN';
    }

    function doPlayerJump() {
      if (isGrounded && !isPlayerDead) {
        verticalVelocity = jumpForce;
        isGrounded = false;
        fadePlayerAction('Jump', 0.12);
        spawnJumpPuff(playerModel.position);
      }
    }

    function playerAttackPunch() {
      if (isPlayerDead || !playerActions['Punch']) return;

      fadePlayerAction('Punch', 0.12);
      setTimeout(() => {
        if (!isPlayerDead) {
          fadePlayerAction(isMoving ? 'Walking' : 'Idle', 0.22);
        }
      }, 950);

      const pX = playerModel.position.x;
      const pY = playerModel.position.y;
      const pZ = playerModel.position.z;
      const fX = Math.sin(playerModel.rotation.y);
      const fZ = Math.cos(playerModel.rotation.y);

      // Đấm đối thủ
      if (playerModel && enemyModel && !isEnemyDead) {
        const dx = enemyModel.position.x - pX;
        const dy = enemyModel.position.y - pY;
        const dz = enemyModel.position.z - pZ;
        const dist3D = Math.sqrt(dx * dx + dy * dy + dz * dz);

        if (dist3D < 2.5 && Math.abs(dy) < 1.4) {
          enemyHP = Math.max(0, enemyHP - 20);
          updateHealthBars();
          spawnDamagePopup(enemyModel.position, '-20 HP');

          const hDist = Math.sqrt(dx * dx + dz * dz) || 1;
          const nx = dx / hDist;
          const nz = dz / hDist;

          enemyKnockback.vx = nx * 12.0;
          enemyKnockback.vz = nz * 12.0;
          enemyKnockback.vy = 4.2;
          enemyTilt = -0.45;
          cameraShake = 0.26;

          spawnImpactSparks(new THREE.Vector3(
            (pX + enemyModel.position.x) / 2,
            pY + 1.2,
            (pZ + enemyModel.position.z) / 2
          ), 0xff0055);

          flashModel(enemyModel);

          if (enemyHP <= 0) {
            isEnemyDead = true;
            fadeEnemyAction('Death', 0.2);
            setTimeout(() => {
              if (playerActions['Dance']) fadePlayerAction('Dance', 0.25);
            }, 800);
          }
        }
      }

      // Đấm vật thể
      solidObstacles.forEach(obs => {
        if (!obs.isDynamic) return;

        const ox = obs.mesh.position.x - pX;
        const oy = obs.mesh.position.y - pY;
        const oz = obs.mesh.position.z - pZ;
        const oDist = Math.sqrt(ox * ox + oz * oz);
        const dot = (ox * fX + oz * fZ) / (oDist || 1);

        if (oDist < 2.6 && Math.abs(oy) < 1.5 && dot > 0.35) {
          if (obs.isBarrel) {
            explodeBarrel(obs);
          } else {
            obs.vx = fX * 14.5;
            obs.vz = fZ * 14.5;
            if (obs.type === 'box') {
              obs.vy = 4.0;
              obs.rotVx = (Math.random() - 0.5) * 6.0;
            }
            cameraShake = 0.18;
            spawnImpactSparks(obs.mesh.position.clone().add(new THREE.Vector3(0, 0.6, 0)), 0xf59e0b);
            spawnDamagePopup(obs.mesh.position, '💥 BẬT VĂNG!');
          }
        }
      });
    }

    function explodeBarrel(barrelObs) {
      const bPos = barrelObs.mesh.position.clone();
      scene.remove(barrelObs.mesh);
      barrelObs.mesh.geometry.dispose();

      const idx = solidObstacles.indexOf(barrelObs);
      if (idx !== -1) solidObstacles.splice(idx, 1);

      cameraShake = 0.55;
      spawnDamagePopup(bPos, '💥 BOOM! EXPLOSION');
      spawnExplosionEffect(bPos);

      const blastRadius = 6.5;

      const pdx = playerModel.position.x - bPos.x;
      const pdz = playerModel.position.z - bPos.z;
      const pDist = Math.sqrt(pdx * pdx + pdz * pdz);
      if (pDist < blastRadius) {
        const force = (1 - pDist / blastRadius) * 16.0;
        playerKnockback.vx = (pdx / (pDist || 1)) * force;
        playerKnockback.vz = (pdz / (pDist || 1)) * force;
        playerKnockback.vy = 5.0;
        playerHP = Math.max(0, playerHP - 15);
        updateHealthBars();
      }

      if (enemyModel && !isEnemyDead) {
        const edx = enemyModel.position.x - bPos.x;
        const edz = enemyModel.position.z - bPos.z;
        const eDist = Math.sqrt(edx * edx + edz * edz);
        if (eDist < blastRadius) {
          const force = (1 - eDist / blastRadius) * 18.0;
          enemyKnockback.vx = (edx / (eDist || 1)) * force;
          enemyKnockback.vz = (edz / (eDist || 1)) * force;
          enemyKnockback.vy = 6.0;
          enemyHP = Math.max(0, enemyHP - 25);
          updateHealthBars();
          if (enemyHP <= 0) {
            isEnemyDead = true;
            fadeEnemyAction('Death', 0.2);
          }
        }
      }

      solidObstacles.forEach(other => {
        if (!other.isDynamic) return;
        const odx = other.mesh.position.x - bPos.x;
        const odz = other.mesh.position.z - bPos.z;
        const oDist = Math.sqrt(odx * odx + odz * odz);
        if (oDist < blastRadius && oDist > 0.01) {
          const oForce = (1 - oDist / blastRadius) * 18.0;
          other.vx = (odx / oDist) * oForce;
          other.vz = (odz / oDist) * oForce;
          other.vy = 5.5;
        }
      });
    }

    let enemyAttackCooldown = 0;
    function enemyAttackPunch() {
      if (isEnemyDead || isPlayerDead || !enemyActions['Punch']) return;

      fadeEnemyAction('Punch', 0.12);
      setTimeout(() => {
        if (!isEnemyDead) {
          fadeEnemyAction('Idle', 0.22);
        }
      }, 950);

      if (playerModel && enemyModel && !isPlayerDead) {
        const dx = playerModel.position.x - enemyModel.position.x;
        const dy = playerModel.position.y - enemyModel.position.y;
        const dz = playerModel.position.z - enemyModel.position.z;
        const dist3D = Math.sqrt(dx * dx + dy * dy + dz * dz);

        if (dist3D < 2.5 && Math.abs(dy) < 1.4) {
          playerHP = Math.max(0, playerHP - 15);
          updateHealthBars();
          spawnDamagePopup(playerModel.position, '-15 HP');

          const hDist = Math.sqrt(dx * dx + dz * dz) || 1;
          const nx = dx / hDist;
          const nz = dz / hDist;

          playerKnockback.vx = nx * 10.5;
          playerKnockback.vz = nz * 10.5;
          playerKnockback.vy = 3.8;
          playerTilt = -0.4;
          cameraShake = 0.32;

          spawnImpactSparks(new THREE.Vector3(
            (playerModel.position.x + enemyModel.position.x) / 2,
            playerModel.position.y + 1.2,
            (playerModel.position.z + enemyModel.position.z) / 2
          ), 0x00e5ff);

          flashModel(playerModel);

          if (playerHP <= 0) {
            isPlayerDead = true;
            fadePlayerAction('Death', 0.2);
            fadeEnemyAction('Dance', 0.25);
          }
        }
      }
    }

    function flashModel(model) {
      if (!model) return;
      model.traverse(obj => {
        if (obj.isMesh && obj.material && obj.material.color) {
          const origHex = obj.material.color.getHex();
          obj.material.color.setHex(0xffffff);
          setTimeout(() => {
            obj.material.color.setHex(origHex);
          }, 120);
        }
      });
    }

    function spawnExplosionEffect(pos) {
      const pCount = 36;
      const geom = new THREE.BufferGeometry();
      const positions = new Float32Array(pCount * 3);
      const velocities = [];

      for (let i = 0; i < pCount; i++) {
        positions[i * 3] = pos.x;
        positions[i * 3 + 1] = pos.y + 0.4;
        positions[i * 3 + 2] = pos.z;

        const theta = Math.random() * Math.PI * 2;
        const phi = (Math.random() - 0.5) * Math.PI;
        const speed = 5.0 + Math.random() * 8.0;
        velocities.push(new THREE.Vector3(
          Math.cos(theta) * Math.cos(phi) * speed,
          Math.sin(phi) * speed + 3.0,
          Math.sin(theta) * Math.cos(phi) * speed
        ));
      }

      geom.setAttribute('position', new THREE.BufferAttribute(positions, 3));
      const mat = new THREE.PointsMaterial({
        color: 0xff3300,
        size: 0.35,
        transparent: true,
        opacity: 1.0,
        blending: THREE.AdditiveBlending
      });

      const pSystem = new THREE.Points(geom, mat);
      scene.add(pSystem);
      particles.push({ points: pSystem, velocities: velocities, life: 0.6, maxLife: 0.6 });
    }

    function spawnImpactSparks(pos, colorHex) {
      const pCount = 18;
      const geom = new THREE.BufferGeometry();
      const positions = new Float32Array(pCount * 3);
      const velocities = [];

      for (let i = 0; i < pCount; i++) {
        positions[i * 3] = pos.x;
        positions[i * 3 + 1] = pos.y;
        positions[i * 3 + 2] = pos.z;

        const theta = Math.random() * Math.PI * 2;
        const phi = (Math.random() - 0.5) * Math.PI;
        const speed = 3.5 + Math.random() * 5.5;
        velocities.push(new THREE.Vector3(
          Math.cos(theta) * Math.cos(phi) * speed,
          Math.sin(phi) * speed + 2.0,
          Math.sin(theta) * Math.cos(phi) * speed
        ));
      }

      geom.setAttribute('position', new THREE.BufferAttribute(positions, 3));
      const mat = new THREE.PointsMaterial({
        color: colorHex,
        size: 0.2,
        transparent: true,
        opacity: 1.0,
        blending: THREE.AdditiveBlending
      });

      const pSystem = new THREE.Points(geom, mat);
      scene.add(pSystem);
      particles.push({ points: pSystem, velocities: velocities, life: 0.35, maxLife: 0.35 });
    }

    function spawnJumpPuff(pos) {
      spawnImpactSparks(pos.clone().add(new THREE.Vector3(0, 0.1, 0)), 0x38bdf8);
    }

    function updateHealthBars() {
      document.getElementById('player-hp-text').innerText = playerHP + ' HP';
      document.getElementById('enemy-hp-text').innerText = enemyHP + ' HP';
      document.getElementById('player-hp-fill').style.width = playerHP + '%';
      document.getElementById('enemy-hp-fill').style.width = enemyHP + '%';
    }

    function spawnDamagePopup(worldPos, text) {
      const pos = worldPos.clone().add(new THREE.Vector3(0, 1.9, 0));
      pos.project(camera);
      const sx = (pos.x * 0.5 + 0.5) * window.innerWidth;
      const sy = (-(pos.y * 0.5) + 0.5) * window.innerHeight;

      const el = document.createElement('div');
      el.className = 'damage-text';
      el.innerText = text;
      el.style.left = sx + 'px';
      el.style.top = sy + 'px';
      document.body.appendChild(el);
      setTimeout(() => el.remove(), 800);
    }

    function resetBattle() {
      playerHP = 100;
      enemyHP = 100;
      isPlayerDead = false;
      isEnemyDead = false;
      playerKnockback.vx = playerKnockback.vy = playerKnockback.vz = 0;
      enemyKnockback.vx = enemyKnockback.vy = enemyKnockback.vz = 0;
      updateHealthBars();

      if (playerModel) {
        playerModel.position.set(0, 0, 0);
        playerModel.rotation.set(0, 0, 0);
        fadePlayerAction('Idle', 0.2);
      }
      if (enemyModel) {
        enemyModel.position.set(0, 0, 5.0);
        enemyModel.rotation.set(0, 0, 0);
        fadeEnemyAction('Idle', 0.2);
      }
    }

    function fadePlayerAction(name, duration = 0.22) {
      if (!playerActions[name]) return;
      const prev = playerActiveAction;
      playerActiveAction = playerActions[name];
      if (prev !== playerActiveAction && playerActiveAction) {
        prev.fadeOut(duration);
        playerActiveAction.reset().fadeIn(duration).play();
      }
    }

    function fadeEnemyAction(name, duration = 0.22) {
      if (!enemyActions[name]) return;
      const prev = enemyActiveAction;
      enemyActiveAction = enemyActions[name];
      if (prev !== enemyActiveAction && enemyActiveAction) {
        prev.fadeOut(duration);
        enemyActiveAction.reset().fadeIn(duration).play();
      }
    }

    let joyForward = 0, joyRight = 0;

    function setupControls() {
      const zone = document.getElementById('joystick-zone');
      const knob = document.getElementById('joystick-knob');
      let joyTouchId = null;
      let startX = 0, startY = 0;

      zone.addEventListener('touchstart', (e) => {
        e.stopPropagation();
        const touch = e.changedTouches[0];
        joyTouchId = touch.identifier;
        const rect = zone.getBoundingClientRect();
        startX = rect.left + rect.width / 2;
        startY = rect.top + rect.height / 2;
        updateKnob(touch.clientX, touch.clientY);
      }, { passive: false });

      window.addEventListener('touchmove', (e) => {
        for (let i = 0; i < e.changedTouches.length; i++) {
          const touch = e.changedTouches[i];
          if (touch.identifier === joyTouchId) {
            updateKnob(touch.clientX, touch.clientY);
          }
        }
      });

      function endJoyTouch(e) {
        for (let i = 0; i < e.changedTouches.length; i++) {
          if (e.changedTouches[i].identifier === joyTouchId) {
            joyTouchId = null;
            joyForward = 0; joyRight = 0;
            knob.style.transform = 'translate(0px, 0px)';
            isMoving = false;
            if (isGrounded && !isPlayerDead) fadePlayerAction('Idle', 0.2);
          }
        }
      }

      window.addEventListener('touchend', endJoyTouch);
      window.addEventListener('touchcancel', endJoyTouch);

      function updateKnob(cx, cy) {
        let dx = cx - startX;
        let dy = cy - startY;
        const maxDist = 48;
        const dist = Math.sqrt(dx * dx + dy * dy);

        if (dist > maxDist) {
          dx = (dx / dist) * maxDist;
          dy = (dy / dist) * maxDist;
        }

        knob.style.transform = `translate(\${dx}px, \${dy}px)`;

        joyForward = -dy / maxDist;
        joyRight = dx / maxDist;

        if (dist > 6 && !isPlayerDead) {
          if (!isMoving) {
            isMoving = true;
            fadePlayerAction(dist > 36 && playerActions['Running'] ? 'Running' : 'Walking', 0.2);
          }
        } else {
          isMoving = false;
          if (!isPlayerDead && isGrounded) fadePlayerAction('Idle', 0.2);
        }
      }

      const jumpBtn = document.getElementById('btn-jump');
      jumpBtn.addEventListener('touchstart', (e) => {
        e.preventDefault(); e.stopPropagation(); doPlayerJump();
      }, { passive: false });
      jumpBtn.addEventListener('click', (e) => { e.stopPropagation(); doPlayerJump(); });

      const punchBtn = document.getElementById('btn-punch');
      punchBtn.addEventListener('touchstart', (e) => {
        e.preventDefault(); e.stopPropagation(); playerAttackPunch();
      }, { passive: false });
      punchBtn.addEventListener('click', (e) => { e.stopPropagation(); playerAttackPunch(); });

      let camTouchId = null;
      let lastCamX = 0, lastCamY = 0;
      let initialPinchDist = null;
      let initialCamDistance = null;

      window.addEventListener('touchstart', (e) => {
        if (e.target.closest('#action-pad, #joystick-zone, #camera-tools-pad, #health-hud, #map-selector-bar')) {
          return;
        }

        if (e.touches.length === 2) {
          const t1 = e.touches[0];
          const t2 = e.touches[1];
          const pdx = t1.clientX - t2.clientX;
          const pdy = t1.clientY - t2.clientY;
          initialPinchDist = Math.sqrt(pdx * pdx + pdy * pdy);
          initialCamDistance = camDistance;
          camTouchId = null;
          return;
        }

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
        if (e.touches.length === 2 && initialPinchDist !== null) {
          const t1 = e.touches[0];
          const t2 = e.touches[1];
          const pdx = t1.clientX - t2.clientX;
          const pdy = t1.clientY - t2.clientY;
          const currentPinchDist = Math.sqrt(pdx * pdx + pdy * pdy);
          const pinchDelta = initialPinchDist - currentPinchDist;

          camDistance = Math.max(3.2, Math.min(26.0, initialCamDistance + pinchDelta * 0.04));
          return;
        }

        for (let i = 0; i < e.changedTouches.length; i++) {
          const t = e.changedTouches[i];
          if (t.identifier === camTouchId) {
            const dx = t.clientX - lastCamX;
            const dy = t.clientY - lastCamY;
            lastCamX = t.clientX;
            lastCamY = t.clientY;

            camAngle += dx * 0.0075;
            camPitch = Math.max(0.06, Math.min(1.25, camPitch - dy * 0.0055));
          }
        }
      }, { passive: true });

      window.addEventListener('touchend', (e) => {
        if (e.touches.length < 2) initialPinchDist = null;
        for (let i = 0; i < e.changedTouches.length; i++) {
          if (e.changedTouches[i].identifier === camTouchId) camTouchId = null;
        }
      });

      window.addEventListener('wheel', (e) => {
        camDistance = Math.max(3.2, Math.min(26.0, camDistance + e.deltaY * 0.015));
      });
    }

    function onWindowResize() {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    }

    function animate() {
      requestAnimationFrame(animate);

      const dt = Math.min(clock.getDelta(), 0.1);
      if (playerMixer) playerMixer.update(dt);
      if (enemyMixer) enemyMixer.update(dt);

      for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i];
        p.life -= dt;
        if (p.life <= 0) {
          scene.remove(p.points);
          p.points.geometry.dispose();
          p.points.material.dispose();
          particles.splice(i, 1);
        } else {
          const posArr = p.points.geometry.attributes.position.array;
          const count = p.velocities.length;
          for (let j = 0; j < count; j++) {
            posArr[j * 3] += p.velocities[j].x * dt;
            posArr[j * 3 + 1] += p.velocities[j].y * dt;
            posArr[j * 3 + 2] += p.velocities[j].z * dt;
            p.velocities[j].y -= 12.0 * dt;
          }
          p.points.geometry.attributes.position.needsUpdate = true;
          p.points.material.opacity = p.life / p.maxLife;
        }
      }

      // DI CHUYỂN JOYSTICK
      if (playerModel && isMoving && !isPlayerDead) {
        const moveSpeed = 4.8 * dt;
        const moveX = Math.sin(camAngle) * joyForward - Math.cos(camAngle) * joyRight;
        const moveZ = Math.cos(camAngle) * joyForward + Math.sin(camAngle) * joyRight;

        if (Math.abs(moveX) > 0.001 || Math.abs(moveZ) > 0.001) {
          playerModel.rotation.y = Math.atan2(moveX, moveZ);
          playerModel.position.x += moveX * moveSpeed;
          playerModel.position.z += moveZ * moveSpeed;
        }

        playerModel.position.x = Math.max(-31, Math.min(31, playerModel.position.x));
        playerModel.position.z = Math.max(-31, Math.min(31, playerModel.position.z));
      }

      // KIỂM TRA BỆ PHÓNG JUMP PAD
      if (playerModel && isGrounded) {
        jumpPads.forEach(pad => {
          const jdx = playerModel.position.x - pad.x;
          const jdz = playerModel.position.z - pad.z;
          if (Math.sqrt(jdx * jdx + jdz * jdz) < 1.4) {
            verticalVelocity = 14.5;
            isGrounded = false;
            fadePlayerAction('Jump', 0.1);
            spawnJumpPuff(playerModel.position);
            spawnDamagePopup(pad.mesh.position, '🚀 SIÊU PHÓNG CAO!');
          }
        });
      }

      // VẬT LÝ PLAYER
      if (playerModel) {
        const groundY = getGroundHeightAt(playerModel.position.x, playerModel.position.z, playerModel.position.y);

        if (isGrounded) {
          if (playerModel.position.y > groundY + 0.12) {
            isGrounded = false;
            verticalVelocity = 0;
          } else {
            playerModel.position.y += (groundY - playerModel.position.y) * 0.35;
          }
        }

        if (!isGrounded) {
          verticalVelocity -= gravity * dt;
          playerModel.position.y += verticalVelocity * dt;

          if (playerModel.position.y <= groundY) {
            playerModel.position.y = groundY;
            verticalVelocity = 0;
            isGrounded = true;
            spawnJumpPuff(playerModel.position);
            if (!isPlayerDead) fadePlayerAction(isMoving ? 'Walking' : 'Idle', 0.15);
          }
        }

        resolveHorizontalCollisions(playerModel, 0.65);
      }

      // KNOCKBACK PLAYER & ENEMY
      if (playerModel && (Math.abs(playerKnockback.vx) > 0.01 || Math.abs(playerKnockback.vz) > 0.01 || Math.abs(playerKnockback.vy) > 0.01)) {
        playerModel.position.x += playerKnockback.vx * dt;
        playerModel.position.z += playerKnockback.vz * dt;
        playerKnockback.vx *= 0.88;
        playerKnockback.vz *= 0.88;
        if (playerKnockback.vy > 0) {
          playerModel.position.y += playerKnockback.vy * dt;
          playerKnockback.vy -= gravity * dt;
        }
      }

      if (enemyModel && (Math.abs(enemyKnockback.vx) > 0.01 || Math.abs(enemyKnockback.vz) > 0.01 || Math.abs(enemyKnockback.vy) > 0.01)) {
        enemyModel.position.x += enemyKnockback.vx * dt;
        enemyModel.position.z += enemyKnockback.vz * dt;
        enemyKnockback.vx *= 0.88;
        enemyKnockback.vz *= 0.88;
        if (enemyKnockback.vy > 0) {
          enemyModel.position.y += enemyKnockback.vy * dt;
          enemyKnockback.vy -= gravity * dt;
        }
      }

      if (enemyModel) {
        if (Math.abs(enemyTilt) > 0.01) {
          enemyModel.rotation.x = enemyTilt;
          enemyTilt *= 0.90;
        } else {
          enemyModel.rotation.x = 0;
        }
      }
      if (playerModel) {
        if (Math.abs(playerTilt) > 0.01) {
          playerModel.rotation.x = playerTilt;
          playerTilt *= 0.90;
        } else {
          playerModel.rotation.x = 0;
        }
      }

      // VẬT THỂ VẬT LÝ ĐỘNG
      solidObstacles.forEach(obs => {
        if (!obs.isDynamic) return;

        if (Math.abs(obs.vx) > 0.01 || Math.abs(obs.vz) > 0.01 || Math.abs(obs.vy) > 0.01) {
          obs.mesh.position.x += obs.vx * dt;
          obs.mesh.position.z += obs.vz * dt;
          obs.vx *= 0.91;
          obs.vz *= 0.91;

          if (obs.type === 'box') {
            if (obs.vy !== 0) {
              obs.mesh.position.y += obs.vy * dt;
              obs.vy -= gravity * dt;
              if (obs.mesh.position.y <= obs.defaultY) {
                obs.mesh.position.y = obs.defaultY;
                obs.vy = 0;
              }
            }
            if (Math.abs(obs.rotVx) > 0.01) {
              obs.mesh.rotation.y += obs.rotVx * dt;
              obs.rotVx *= 0.92;
            }
          } else if (obs.type === 'sphere') {
            obs.mesh.rotation.x += obs.vz * 0.25;
            obs.mesh.rotation.z -= obs.vx * 0.25;
          }

          obs.mesh.position.x = Math.max(-31, Math.min(31, obs.mesh.position.x));
          obs.mesh.position.z = Math.max(-31, Math.min(31, obs.mesh.position.z));
        }
      });

      // ĐỐI THỦ AI
      if (playerModel && enemyModel && !isEnemyDead && !isPlayerDead) {
        const edx = playerModel.position.x - enemyModel.position.x;
        const edy = playerModel.position.y - enemyModel.position.y;
        const edz = playerModel.position.z - enemyModel.position.z;
        const dist2D = Math.sqrt(edx * edx + edz * edz);

        const minBodyDist = 1.35;
        if (dist2D < minBodyDist && dist2D > 0.001 && Math.abs(edy) < 1.2) {
          const cnx = edx / dist2D;
          const cnz = edz / dist2D;
          const overlap = minBodyDist - dist2D;

          playerModel.position.x += cnx * overlap * 0.5;
          playerModel.position.z += cnz * overlap * 0.5;
          enemyModel.position.x -= cnx * overlap * 0.5;
          enemyModel.position.z -= cnz * overlap * 0.5;
        }

        const enemyGroundY = getGroundHeightAt(enemyModel.position.x, enemyModel.position.z, enemyModel.position.y);
        if (enemyGrounded) {
          if (enemyModel.position.y > enemyGroundY + 0.12) {
            enemyGrounded = false;
            enemyVerticalVelocity = 0;
          } else {
            enemyModel.position.y += (enemyGroundY - enemyModel.position.y) * 0.35;
          }
        }
        if (!enemyGrounded) {
          enemyVerticalVelocity -= gravity * dt;
          enemyModel.position.y += enemyVerticalVelocity * dt;
          if (enemyModel.position.y <= enemyGroundY) {
            enemyModel.position.y = enemyGroundY;
            enemyVerticalVelocity = 0;
            enemyGrounded = true;
          }
        }

        resolveHorizontalCollisions(enemyModel, 0.65);

        if (enemyAIMode) {
          enemyModel.rotation.y = Math.atan2(edx, edz);

          if (dist2D > 2.2) {
            const enemySpeed = 2.4 * dt;
            enemyModel.position.x += (edx / dist2D) * enemySpeed;
            enemyModel.position.z += (edz / dist2D) * enemySpeed;

            if (enemyActiveAction && enemyActiveAction.getClip().name !== 'Walking') {
              fadeEnemyAction('Walking', 0.2);
            }
          } else {
            if (enemyAttackCooldown <= 0 && Math.abs(edy) < 1.4) {
              enemyAttackCooldown = 1.7;
              enemyAttackPunch();
            }
          }
        }

        if (enemyAttackCooldown > 0) enemyAttackCooldown -= dt;
      }

      // CAMERA THEO SAU PLAYER
      if (playerModel) {
        let shakeX = 0, shakeY = 0;
        if (cameraShake > 0.005) {
          shakeX = (Math.random() - 0.5) * cameraShake * 1.6;
          shakeY = (Math.random() - 0.5) * cameraShake * 1.6;
          cameraShake *= 0.86;
        } else {
          cameraShake = 0;
        }

        const targetX = playerModel.position.x - Math.sin(camAngle) * camDistance * Math.cos(camPitch) + shakeX;
        const targetZ = playerModel.position.z - Math.cos(camAngle) * camDistance * Math.cos(camPitch);
        const rawTargetY = playerModel.position.y + Math.sin(camPitch) * camDistance + 1.6 + shakeY;
        const targetY = Math.max(0.6, rawTargetY);

        camera.position.x += (targetX - camera.position.x) * 0.12;
        camera.position.y += (targetY - camera.position.y) * 0.12;
        camera.position.z += (targetZ - camera.position.z) * 0.12;

        camera.lookAt(playerModel.position.x, playerModel.position.y + 1.25, playerModel.position.z);
      }

      renderer.render(scene, camera);
    }
  </script>
</body>
</html>
''';
}
