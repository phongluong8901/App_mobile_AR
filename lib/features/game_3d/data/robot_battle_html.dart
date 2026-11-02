/// Mã nguồn HTML, CSS và JavaScript của Three.js 3D Robot Battle Arena.
/// Đã được nâng cấp toàn diện sang Bản đồ 3D thực tế (.GLB Game Levels) kết hợp Raycasting Physics:
/// 1. Tải bản đồ 3D thực tế dạng file .GLB (Collision World Arena, Gothic Dungeon, Spaceship Hallway).
/// 2. Động cơ Raycasting Physics: Tự động quét bề mặt lưới 3D (Mesh Surface) của file .glb để tính độ cao sàn, dốc dốc, bậc thang, và phát hiện va chạm tường ngăn không cho đi xuyên.
/// 3. Bổ sung các đồ vật vật lý tương tác: Thùng phuy thuốc nổ đỏ (sóng xung kích hất tung), thùng gỗ xếp tầng, quả cầu kim loại, bệ phóng Jump Pad.
/// 4. Hỗ trợ nạp bất kỳ bản đồ .glb tùy chọn nào từ Internet.
class RobotBattleHtml {
  RobotBattleHtml._();

  static const String content = '''
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>3D Robot Battle Arena - Real GLB Worlds & Physics</title>
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
    /* THANH CHỌN BẢN ĐỒ 3D (.GLB WORLDS) */
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
    /* POPUP CHỮ VẬT LÝ */
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
    <div id="loading-text">Đang tải Bản Đồ 3D Game Level (.GLB)...</div>
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

  <!-- THANH CHỌN BẢN ĐỒ 3D (.GLB WORLDS) -->
  <div id="map-selector-bar">
    <button class="btn-map-tab active" id="tab-map-arena" onclick="loadGlbMap('arena')">🏛️ Đấu Trường Arena (.GLB)</button>
    <button class="btn-map-tab" id="tab-map-dungeon" onclick="loadGlbMap('dungeon')">🏰 Lâu Đài Hầm Ngục (.GLB)</button>
    <button class="btn-map-tab" id="tab-map-space" onclick="loadGlbMap('space')">🚀 Trạm Không Gian (.GLB)</button>
    <button class="btn-map-tab" id="tab-map-custom" onclick="promptCustomMapUrl()">🌐 Nhập Link .GLB Khác</button>
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

    // HỆ THỐNG VẬT LÝ RAYCASTING BẢN ĐỒ .GLB & ĐỒ VẬT ĐỘNG
    const mapColliderMeshes = [];   // Danh sách các Mesh của file .GLB để quét tia Raycast va chạm
    let currentMapObject = null;
    let solidObstacles = [];        // Thùng gỗ, thùng phuy nổ, quả cầu
    let jumpPads = [];
    const particles = [];

    // TIA RAYCASTER TÍNH TOÁN ĐỘ CAO SÀN VÀ VA CHẠM TƯỜNG TRÊN .GLB
    const downRay = new THREE.Raycaster();
    const downDir = new THREE.Vector3(0, -1, 0);

    const forwardRay = new THREE.Raycaster();

    const GLB_MAP_URLS = {
      // 1. Map Arena game chuyên nghiệp của Three.js (có ram dốc, cầu thang, hành lang, trụ cột)
      arena: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/collision-world.glb',
      // 2. Lâu đài hầm ngục Gothic
      dungeon: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/dungeon_warkarma.glb',
      // 3. Trạm không gian tương lai
      space: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/space_ship_hallway.glb'
    };

    init();
    animate();

    function init() {
      const container = document.getElementById('canvas-container');
      clock = new THREE.Clock();

      scene = new THREE.Scene();
      scene.background = new THREE.Color(0x070B14);
      scene.fog = new THREE.FogExp2(0x070B14, 0.012);

      camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 150);

      renderer = new THREE.WebGLRenderer({ antialias: true });
      renderer.setPixelRatio(window.devicePixelRatio);
      renderer.setSize(window.innerWidth, window.innerHeight);
      renderer.shadowMap.enabled = true;
      renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      container.appendChild(renderer.domElement);

      const hemiLight = new THREE.HemisphereLight(0xffffff, 0x1e293b, 0.9);
      scene.add(hemiLight);

      const dirLight = new THREE.DirectionalLight(0x00e5ff, 1.5);
      dirLight.position.set(15, 25, 15);
      dirLight.castShadow = true;
      dirLight.shadow.mapSize.width = 1024;
      dirLight.shadow.mapSize.height = 1024;
      dirLight.shadow.camera.near = 0.5;
      dirLight.shadow.camera.far = 60;
      dirLight.shadow.camera.left = -25;
      dirLight.shadow.camera.right = 25;
      dirLight.shadow.camera.top = 25;
      dirLight.shadow.camera.bottom = -25;
      scene.add(dirLight);

      // TẢI BẢN ĐỒ .GLB CHÍNH THỨC BAN ĐẦU
      loadGlbMap('arena');

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
        });

      }, undefined, function (error) {
        console.error('Lỗi tải Robot GLB:', error);
      });

      setupControls();
      window.addEventListener('resize', onWindowResize, false);
    }

    // TẢI BẢN ĐỒ DẠNG MÔ HÌNH 3D .GLB THỰC TẾ & TỰ ĐỘNG SINH VẬT LÝ RAYCASTING
    function loadGlbMap(mapTypeKey, customUrl = null) {
      const url = customUrl || GLB_MAP_URLS[mapTypeKey];
      if (!url) return;

      document.getElementById('loading-overlay').style.display = 'flex';
      document.getElementById('loading-overlay').style.opacity = '1';
      document.getElementById('loading-text').innerText = 'Đang tải Bản Đồ 3D (.GLB) & Tính toán Vật Lý...';

      // Cập nhật nút tab active
      document.querySelectorAll('.btn-map-tab').forEach(b => b.classList.remove('active'));
      const activeBtn = document.getElementById('tab-map-' + mapTypeKey);
      if (activeBtn) activeBtn.classList.add('active');

      // Dọn dẹp bản đồ cũ
      if (currentMapObject) {
        scene.remove(currentMapObject);
        currentMapObject.traverse(child => {
          if (child.geometry) child.geometry.dispose();
          if (child.material) {
            if (Array.isArray(child.material)) child.material.forEach(m => m.dispose());
            else child.material.dispose();
          }
        });
      }
      mapColliderMeshes.length = 0;
      solidObstacles.forEach(obs => {
        scene.remove(obs.mesh);
        if (obs.mesh.geometry) obs.mesh.geometry.dispose();
      });
      solidObstacles.length = 0;
      jumpPads.forEach(pad => scene.remove(pad.mesh));
      jumpPads.length = 0;

      const loader = new THREE.GLTFLoader();
      loader.load(url, function (gltf) {
        currentMapObject = gltf.scene;

        // Tinh chỉnh tỷ lệ và vị trí phù hợp cho từng loại map
        if (mapTypeKey === 'arena') {
          currentMapObject.scale.set(1.15, 1.15, 1.15);
          currentMapObject.position.set(0, 0, 0);
        } else if (mapTypeKey === 'dungeon') {
          currentMapObject.scale.set(0.75, 0.75, 0.75);
          currentMapObject.position.set(0, 0, 0);
        } else if (mapTypeKey === 'space') {
          currentMapObject.scale.set(1.0, 1.0, 1.0);
          currentMapObject.position.set(0, 0, 0);
        } else {
          currentMapObject.scale.set(2.0, 2.0, 2.0);
          currentMapObject.position.set(0, 0, 0);
        }

        // DUYỆT TẤT CẢ MESH TRONG BẢN ĐỒ .GLB ĐỂ KÍCH HOẠT ĐỔ BÓNG VÀ ĐĂNG KÝ VẬT LÝ VA CHẠM
        currentMapObject.traverse(child => {
          if (child.isMesh) {
            child.castShadow = true;
            child.receiveShadow = true;
            if (child.geometry) {
              child.geometry.computeVertexNormals();
            }
            mapColliderMeshes.push(child);
          }
        });

        scene.add(currentMapObject);

        // THÊM CÁC ĐỒ VẬT VẬT LÝ TƯƠNG TÁC LÊN MAP (THÙNG PHUY NỔ, THÙNG GỖ, BÓNG, JUMP PAD)
        spawnInteractiveProps();

        resetBattle();

        document.getElementById('loading-overlay').style.opacity = '0';
        setTimeout(() => {
          document.getElementById('loading-overlay').style.display = 'none';
        }, 500);

        spawnDamagePopup(new THREE.Vector3(0, 2, 0), '✨ ĐÃ TẢI MAP 3D THỰC TẾ!');
      }, undefined, function (error) {
        console.error('Lỗi tải file .glb map:', error);
        alert('Không thể tải bản đồ 3D từ link này. Đang dùng map dự phòng!');
        document.getElementById('loading-overlay').style.display = 'none';
      });
    }

    // NHẬP LINK MAP .GLB TÙY Ý TỪ INTERNET
    function promptCustomMapUrl() {
      const url = prompt(
        'Nhập URL file mô hình 3D bản đồ (.glb) từ mạng (Three.js, Sketchfab, GitHub):',
        'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/collision-world.glb'
      );
      if (url && url.trim().length > 5) {
        loadGlbMap('custom', url.trim());
      }
    }

    // SINH ĐỒ VẬT VẬT LÝ TƯƠNG TÁC TRÊN BẢN ĐỒ .GLB
    function spawnInteractiveProps() {
      const crateMat = new THREE.MeshStandardMaterial({ color: 0xf59e0b, roughness: 0.35, metalness: 0.35 });
      const barrelMat = new THREE.MeshStandardMaterial({ color: 0xdc2626, roughness: 0.25, metalness: 0.5 });
      const metalSphereMat = new THREE.MeshStandardMaterial({ color: 0x38bdf8, roughness: 0.1, metalness: 0.95 });

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
          vx: 0, vy: 0, vz: 0,
          rotVx: 0,
          defaultY: y,
          ...extra
        });
      }

      // 1. Thùng gỗ xếp tầng (vật lý va đập & trèo lên)
      addBox(-5, 0.6, 3, 1.2, 1.2, 1.2, crateMat);
      addBox(-3.6, 0.6, 3, 1.2, 1.2, 1.2, crateMat);
      addBox(-4.3, 1.8, 3, 1.2, 1.2, 1.2, crateMat);

      // 2. Thùng phuy thuốc nổ đỏ (phát nổ uy lực)
      const bMesh = new THREE.Mesh(new THREE.CylinderGeometry(0.65, 0.65, 1.6, 24), barrelMat);
      bMesh.position.set(4, 0.8, -4);
      bMesh.castShadow = true;
      bMesh.receiveShadow = true;
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

      // 3. Quả cầu kim loại lăn trôi
      const sph = new THREE.Mesh(new THREE.SphereGeometry(1.0, 32, 32), metalSphereMat);
      sph.position.set(5, 1.0, 5);
      sph.castShadow = true;
      scene.add(sph);
      solidObstacles.push({
        type: 'sphere',
        mesh: sph,
        radius: 1.0,
        isDynamic: true,
        isBarrel: false,
        vx: 0, vy: 0, vz: 0,
        defaultY: 1.0
      });

      // 4. Bệ phóng Jump Pad
      const padGeo = new THREE.CylinderGeometry(1.5, 1.7, 0.15, 32);
      const padMat = new THREE.MeshStandardMaterial({
        color: 0x00e5ff,
        emissive: 0x00a8cc,
        roughness: 0.2,
        metalness: 0.8
      });
      const pad = new THREE.Mesh(padGeo, padMat);
      pad.position.set(0, 0.08, -8);
      scene.add(pad);
      jumpPads.push({ mesh: pad, x: 0, z: -8 });
    }

    // ĐỘNG CƠ RAYCASTING TÍNH TOÁN ĐỘ CAO SÀN CHÍNH XÁC TRÊN BỀ MẶT MESH .GLB
    function getGroundHeightAt(x, z, currentY) {
      let floorY = 0; // Sàn cơ sở

      // 1. Quét tia Raycast thẳng đứng xuống dưới lên toàn bộ Mesh của bản đồ .GLB
      if (mapColliderMeshes.length > 0) {
        downRay.set(new THREE.Vector3(x, currentY + 1.5, z), downDir);
        downRay.far = 16.0;
        const hits = downRay.intersectObjects(mapColliderMeshes, false);

        if (hits.length > 0) {
          for (let i = 0; i < hits.length; i++) {
            const hit = hits[i];
            const hitY = hit.point.y;

            // Kiểm tra mặt phẳng có thể đứng được (normal hướng lên)
            let isWalkable = true;
            if (hit.face && hit.face.normal) {
              const worldNormal = hit.face.normal.clone().transformDirection(hit.object.matrixWorld);
              if (worldNormal.y < 0.3) isWalkable = false; // Dốc đứng hoặc vách tường
            }

            if (isWalkable && currentY >= hitY - 0.65) {
              if (hitY > floorY) {
                floorY = hitY;
                break;
              }
            }
          }
        }
      }

      // 2. Kiểm tra độ cao của các thùng gỗ vật lý động
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

    // CHẶN VA CHẠM TƯỜNG TRÊN .GLB VÀ VẬT THỂ (CHỐNG ĐI XUYÊN TƯỜNG)
    function resolveCollisions(model, radius = 0.65) {
      const px = model.position.x;
      const py = model.position.y;
      const pz = model.position.z;

      // 1. Quét tia ngang kiểm tra va chạm tường thành của bản đồ .GLB
      if (mapColliderMeshes.length > 0) {
        const angles = [0, Math.PI / 2, Math.PI, -Math.PI / 2];
        for (let i = 0; i < angles.length; i++) {
          const ang = angles[i];
          const dir = new THREE.Vector3(Math.sin(ang), 0, Math.cos(ang));
          forwardRay.set(new THREE.Vector3(px, py + 0.6, pz), dir);
          forwardRay.far = radius + 0.15;
          const hits = forwardRay.intersectObjects(mapColliderMeshes, false);
          if (hits.length > 0) {
            const hit = hits[0];
            const pushDist = (radius + 0.15) - hit.distance;
            model.position.x -= dir.x * pushDist;
            model.position.z -= dir.z * pushDist;
          }
        }
      }

      // 2. Va chạm với thùng gỗ và quả cầu
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
              const dL = px - minX, dR = maxX - px, dT = pz - minZ, dB = maxZ - pz;
              const minD = Math.min(dL, dR, dT, dB);
              if (minD === dL) { model.position.x = minX; if (obs.isDynamic) obs.vx = -3.5; }
              else if (minD === dR) { model.position.x = maxX; if (obs.isDynamic) obs.vx = 3.5; }
              else if (minD === dT) { model.position.z = minZ; if (obs.isDynamic) obs.vz = -3.5; }
              else { model.position.z = maxZ; if (obs.isDynamic) obs.vz = 3.5; }
            }
          }
        } else if (obs.type === 'sphere') {
          const sx = obs.mesh.position.x, sz = obs.mesh.position.z;
          const dx = px - sx, dz = pz - sz;
          const dist = Math.sqrt(dx * dx + dz * dz);
          const minD = radius + obs.radius;
          if (dist < minD && dist > 0.001) {
            const overlap = minD - dist;
            const nx = dx / dist, nz = dz / dist;
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

      // DI CHUYỂN BẰNG JOYSTICK
      if (playerModel && isMoving && !isPlayerDead) {
        const moveSpeed = 4.8 * dt;
        const moveX = Math.sin(camAngle) * joyForward - Math.cos(camAngle) * joyRight;
        const moveZ = Math.cos(camAngle) * joyForward + Math.sin(camAngle) * joyRight;

        if (Math.abs(moveX) > 0.001 || Math.abs(moveZ) > 0.001) {
          playerModel.rotation.y = Math.atan2(moveX, moveZ);
          playerModel.position.x += moveX * moveSpeed;
          playerModel.position.z += moveZ * moveSpeed;
        }

        playerModel.position.x = Math.max(-32, Math.min(32, playerModel.position.x));
        playerModel.position.z = Math.max(-32, Math.min(32, playerModel.position.z));
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

      // VẬT LÝ PLAYER: TÍNH TOÁN RAYCASTING TRỌNG LỰC TRÊN BỀ MẶT MESH .GLB
      if (playerModel) {
        const groundY = getGroundHeightAt(playerModel.position.x, playerModel.position.z, playerModel.position.y);

        if (isGrounded) {
          if (playerModel.position.y > groundY + 0.12) {
            isGrounded = false;
            verticalVelocity = 0;
          } else {
            // Tự động bước lên các bậc dốc, bậc thang của map .glb
            playerModel.position.y += (groundY - playerModel.position.y) * 0.38;
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

        // CHẶN VA CHẠM TƯỜNG TRÊN .GLB
        resolveCollisions(playerModel, 0.65);
      }

      // KNOCKBACK
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

      // ĐỒ VẬT VẬT LÝ ĐỘNG
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

          obs.mesh.position.x = Math.max(-32, Math.min(32, obs.mesh.position.x));
          obs.mesh.position.z = Math.max(-32, Math.min(32, obs.mesh.position.z));
        }
      });

      // ĐỐI THỦ AI: ÁP DỤNG VẬT LÝ RAYCASTING TRÊN .GLB
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
            enemyModel.position.y += (enemyGroundY - enemyModel.position.y) * 0.38;
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

        resolveCollisions(enemyModel, 0.65);

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
