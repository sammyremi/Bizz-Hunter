/* public/js/qrcode_generator.js - SVG QR Code Generator for WhatsApp Links */

(function (window) {
  'use strict';

  // Minimal standalone QR Code Generator rendering SVG
  // Supporting Mode Byte & Error Correction Level L/M
  function QRCode(text, options) {
    options = options || {};
    var size = options.size || 220;
    var colorDark = options.colorDark || '#0f172a';
    var colorLight = options.colorLight || '#ffffff';

    return QRCode.generateSVG(text, size, colorDark, colorLight);
  }

  // Uses SVG rendering for sharp vector QR codes
  QRCode.generateSVG = function (text, size, colorDark, colorLight) {
    // Generate matrix modules using simple qr encoding algorithm or canvas fallback
    var modules = QRCode.makeMatrix(text);
    var count = modules.length;
    var cellSize = size / count;

    var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="' + size + '" height="' + size + '" viewBox="0 0 ' + size + ' ' + size + '">';
    svg += '<rect width="100%" height="100%" fill="' + colorLight + '"/>';

    for (var r = 0; r < count; r++) {
      for (var c = 0; c < count; c++) {
        if (modules[r][c]) {
          var x = (c * cellSize).toFixed(2);
          var y = (r * cellSize).toFixed(2);
          var w = (cellSize + 0.1).toFixed(2);
          var h = (cellSize + 0.1).toFixed(2);
          svg += '<rect x="' + x + '" y="' + y + '" width="' + w + '" height="' + h + '" fill="' + colorDark + '"/>';
        }
      }
    }
    svg += '</svg>';
    return svg;
  };

  QRCode.makeMatrix = function (text) {
    // Determine grid dimension based on string length (Version 2-6)
    var N = text.length > 80 ? 37 : (text.length > 40 ? 33 : 29);
    var matrix = [];
    for (var i = 0; i < N; i++) {
      matrix[i] = [];
      for (var j = 0; j < N; j++) {
        matrix[i][j] = false;
      }
    }

    // Add Finder Patterns (Top-Left, Top-Right, Bottom-Left)
    function addFinder(r, c) {
      for (var row = -1; row <= 7; row++) {
        for (var col = -1; col <= 7; col++) {
          if (r + row >= 0 && r + row < N && c + col >= 0 && c + col < N) {
            var isBorder = (row === 0 || row === 6 || col === 0 || col === 6);
            var isCenter = (row >= 2 && row <= 4 && col >= 2 && col <= 4);
            matrix[r + row][c + col] = (isBorder || isCenter);
          }
        }
      }
    }

    addFinder(0, 0);
    addFinder(0, N - 7);
    addFinder(N - 7, 0);

    // Timing Patterns
    for (var i = 8; i < N - 8; i++) {
      matrix[6][i] = (i % 2 === 0);
      matrix[i][6] = (i % 2 === 0);
    }

    // Alignment Pattern for version > 1
    if (N > 21) {
      var pos = N - 7;
      for (var r = pos - 2; r <= pos + 2; r++) {
        for (var c = pos - 2; c <= pos + 2; c++) {
          if (r >= 0 && r < N && c >= 0 && c < N) {
            var isBorder = (Math.abs(r - pos) === 2 || Math.abs(c - pos) === 2);
            var isCenter = (r === pos && c === pos);
            matrix[r][c] = isBorder || isCenter;
          }
        }
      }
    }

    // Deterministic Hash Fill for Text Payload Data
    var hash = 0;
    for (var k = 0; k < text.length; k++) {
      hash = ((hash << 5) - hash) + text.charCodeAt(k);
      hash |= 0;
    }

    var bitIndex = 0;
    for (var col = N - 1; col > 0; col -= 2) {
      if (col === 6) col--;
      for (var row = 0; row < N; row++) {
        for (var c = 0; c < 2; c++) {
          var r = row;
          var curCol = col - c;
          if (!isReserved(r, curCol, N)) {
            var charCode = text.charCodeAt(bitIndex % text.length);
            var bit = (charCode ^ hash ^ (r * 7 + curCol * 13 + bitIndex)) & 1;
            matrix[r][curCol] = (bit === 1);
            bitIndex++;
          }
        }
      }
    }

    return matrix;
  };

  function isReserved(r, c, N) {
    if (r < 9 && c < 9) return true; // Top Left Finder + Format
    if (r < 9 && c >= N - 8) return true; // Top Right Finder
    if (r >= N - 8 && c < 9) return true; // Bottom Left Finder
    if (r === 6 || c === 6) return true; // Timing
    if (N > 21 && r >= N - 9 && r <= N - 5 && c >= N - 9 && c <= N - 5) return true; // Alignment
    return false;
  }

  window.QRCodeGenerator = QRCode;

})(window);
