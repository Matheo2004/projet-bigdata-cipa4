<?php

$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$requestUri = str_replace('/WEB', '', $requestUri);

// API
if (strpos($requestUri, '/api') === 0) {
    require __DIR__ . '/api/index.php';
    exit;
}

// FRONT
header('Location: front/public/');
exit;