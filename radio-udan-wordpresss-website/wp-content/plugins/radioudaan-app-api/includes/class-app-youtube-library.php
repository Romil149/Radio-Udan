<?php
/**
 * YouTube Data API v3 library backend for the mobile app.
 *
 * @package RadioUdaanAppApi
 */

defined( 'ABSPATH' ) || exit;

/**
 * Server-side YouTube channel content (playlists, recent, search).
 */
class RadioUdaan_App_Youtube_Library {

	const OPTION_API_KEY             = 'radioudaan_youtube_api_key';
	const OPTION_CHANNEL             = 'radioudaan_youtube_channel';
	const OPTION_FEATURED_PLAYLISTS  = 'radioudaan_youtube_featured_playlists';

	const DEFAULT_CHANNEL_ID         = 'UCuVsMztJhpj4go-Oexje4KA';
	const DEFAULT_CHANNEL_HANDLE     = '@radioudaan';

	const CACHE_PLAYLISTS_TTL        = HOUR_IN_SECONDS;
	const CACHE_RECENT_TTL           = 900;
	const CACHE_SEARCH_TTL           = 300;

	const API_BASE                   = 'https://www.googleapis.com/youtube/v3/';

	/**
	 * Admin AJAX for playlist picker.
	 */
	public static function init_admin() {
		add_action( 'wp_ajax_radioudaan_youtube_load_playlists', array( __CLASS__, 'ajax_load_playlists' ) );
	}

	/**
	 * @return string
	 */
	public static function get_api_key() {
		return trim( (string) get_option( self::OPTION_API_KEY, '' ) );
	}

	/**
	 * Channel handle (@radioudaan) or ID (UC…).
	 *
	 * @return string
	 */
	public static function get_channel_input() {
		$stored = trim( (string) get_option( self::OPTION_CHANNEL, '' ) );
		return $stored !== '' ? $stored : self::DEFAULT_CHANNEL_HANDLE;
	}

	/**
	 * @return string[]
	 */
	public static function get_featured_playlist_ids() {
		$raw = get_option( self::OPTION_FEATURED_PLAYLISTS, '[]' );
		if ( is_array( $raw ) ) {
			$ids = $raw;
		} else {
			$decoded = json_decode( (string) $raw, true );
			$ids     = is_array( $decoded ) ? $decoded : array();
		}

		$clean = array();
		foreach ( $ids as $id ) {
			$id = sanitize_text_field( (string) $id );
			if ( $id !== '' ) {
				$clean[] = $id;
			}
		}

		return array_values( array_unique( $clean ) );
	}

	/**
	 * Clear cached YouTube responses after settings change.
	 */
	public static function invalidate_cache() {
		global $wpdb;

		$wpdb->query(
			$wpdb->prepare(
				"DELETE FROM {$wpdb->options} WHERE option_name LIKE %s OR option_name LIKE %s",
				$wpdb->esc_like( '_transient_ru_yt_' ) . '%',
				$wpdb->esc_like( '_transient_timeout_ru_yt_' ) . '%'
			)
		);
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function rest_recent( WP_REST_Request $request ) {
		$per_page = min( 50, max( 1, (int) $request->get_param( 'per_page' ) ) );
		$result   = self::get_recent_videos( $per_page );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		$response = new WP_REST_Response( $result, 200 );
		$response->header( 'Cache-Control', 'public, max-age=' . self::CACHE_RECENT_TTL );
		return $response;
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function rest_playlists( WP_REST_Request $request ) {
		unset( $request );
		$result = self::get_all_playlists();
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		$response = new WP_REST_Response(
			array(
				'items' => $result,
			),
			200
		);
		$response->header( 'Cache-Control', 'public, max-age=' . self::CACHE_PLAYLISTS_TTL );
		return $response;
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function rest_featured_playlists( WP_REST_Request $request ) {
		unset( $request );
		$result = self::get_featured_playlists();
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		$response = new WP_REST_Response(
			array(
				'items' => $result,
			),
			200
		);
		$response->header( 'Cache-Control', 'public, max-age=' . self::CACHE_PLAYLISTS_TTL );
		return $response;
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function rest_playlist_videos( WP_REST_Request $request ) {
		$playlist_id = sanitize_text_field( (string) $request->get_param( 'id' ) );
		$per_page    = min( 50, max( 1, (int) $request->get_param( 'per_page' ) ) );
		$page        = max( 1, (int) $request->get_param( 'page' ) );

		if ( $playlist_id === '' ) {
			return new WP_Error(
				'invalid_playlist',
				__( 'Playlist ID is required.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$result = self::get_playlist_videos( $playlist_id, $per_page, $page );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		$response = new WP_REST_Response( $result, 200 );
		$response->header( 'Cache-Control', 'public, max-age=' . self::CACHE_PLAYLISTS_TTL );
		return $response;
	}

	/**
	 * @param WP_REST_Request $request Request.
	 * @return WP_REST_Response|WP_Error
	 */
	public static function rest_search( WP_REST_Request $request ) {
		$query = trim( (string) $request->get_param( 'q' ) );
		if ( $query === '' ) {
			return new WP_Error(
				'missing_query',
				__( 'Search query is required.', 'radioudaan-app-api' ),
				array( 'status' => 400 )
			);
		}

		$per_page = min( 50, max( 1, (int) $request->get_param( 'per_page' ) ) );
		$page     = max( 1, (int) $request->get_param( 'page' ) );
		$result   = self::search_videos( $query, $per_page, $page );
		if ( is_wp_error( $result ) ) {
			return $result;
		}

		$response = new WP_REST_Response( $result, 200 );
		$response->header( 'Cache-Control', 'public, max-age=' . self::CACHE_SEARCH_TTL );
		return $response;
	}

	/**
	 * Admin: load channel playlists for featured picker.
	 */
	public static function ajax_load_playlists() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_send_json_error( array( 'message' => __( 'Insufficient permissions.', 'radioudaan-app-api' ) ), 403 );
		}

		check_ajax_referer( 'radioudaan_youtube_admin', 'nonce' );

		$playlists = self::get_all_playlists( true );
		if ( is_wp_error( $playlists ) ) {
			wp_send_json_error( array( 'message' => $playlists->get_error_message() ), 400 );
		}

		wp_send_json_success(
			array(
				'items' => $playlists,
			)
		);
	}

	/**
	 * @param int $per_page Per page.
	 * @return array<string,mixed>|WP_Error
	 */
	public static function get_recent_videos( $per_page = 20 ) {
		$channel_id = self::resolve_channel_id();
		if ( is_wp_error( $channel_id ) ) {
			return $channel_id;
		}

		$cache_key = 'ru_yt_recent_' . md5( $channel_id . '|' . (int) $per_page );
		$cached    = get_transient( $cache_key );
		if ( is_array( $cached ) ) {
			return $cached;
		}

		$uploads_id = self::get_uploads_playlist_id( $channel_id );
		if ( is_wp_error( $uploads_id ) ) {
			return $uploads_id;
		}

		$data = self::api_get(
			'playlistItems',
			array(
				'part'       => 'snippet,contentDetails',
				'playlistId' => $uploads_id,
				'maxResults' => (int) $per_page,
			)
		);
		if ( is_wp_error( $data ) ) {
			return $data;
		}

		$videos = self::map_playlist_items_to_videos( isset( $data['items'] ) ? $data['items'] : array() );
		$result = array(
			'items'    => $videos,
			'per_page' => (int) $per_page,
		);

		set_transient( $cache_key, $result, self::CACHE_RECENT_TTL );
		return $result;
	}

	/**
	 * @param bool $skip_cache Skip transient (admin refresh).
	 * @return array<int,array<string,mixed>>|WP_Error
	 */
	public static function get_all_playlists( $skip_cache = false ) {
		$channel_id = self::resolve_channel_id();
		if ( is_wp_error( $channel_id ) ) {
			return $channel_id;
		}

		$cache_key = 'ru_yt_playlists_' . md5( $channel_id );
		if ( ! $skip_cache ) {
			$cached = get_transient( $cache_key );
			if ( is_array( $cached ) ) {
				return $cached;
			}
		}

		$items    = array();
		$page_token = '';
		do {
			$params = array(
				'part'       => 'snippet,contentDetails',
				'channelId'  => $channel_id,
				'maxResults' => 50,
			);
			if ( $page_token !== '' ) {
				$params['pageToken'] = $page_token;
			}

			$data = self::api_get( 'playlists', $params );
			if ( is_wp_error( $data ) ) {
				return $data;
			}

			foreach ( isset( $data['items'] ) ? $data['items'] : array() as $item ) {
				$mapped = self::map_playlist( $item );
				if ( $mapped ) {
					$items[] = $mapped;
				}
			}

			$page_token = isset( $data['nextPageToken'] ) ? (string) $data['nextPageToken'] : '';
		} while ( $page_token !== '' && count( $items ) < 200 );

		if ( ! $skip_cache ) {
			set_transient( $cache_key, $items, self::CACHE_PLAYLISTS_TTL );
		}

		return $items;
	}

	/**
	 * @return array<int,array<string,mixed>>|WP_Error
	 */
	public static function get_featured_playlists() {
		$featured_ids = self::get_featured_playlist_ids();
		if ( empty( $featured_ids ) ) {
			return array();
		}

		$all = self::get_all_playlists();
		if ( is_wp_error( $all ) ) {
			return $all;
		}

		$by_id = array();
		foreach ( $all as $playlist ) {
			$by_id[ $playlist['id'] ] = $playlist;
		}

		$featured = array();
		foreach ( $featured_ids as $id ) {
			if ( isset( $by_id[ $id ] ) ) {
				$featured[] = $by_id[ $id ];
			}
		}

		return $featured;
	}

	/**
	 * Featured playlist rows for the admin picker (titles + thumbnails when cached).
	 *
	 * @return array<int,array<string,mixed>>
	 */
	public static function get_featured_playlist_admin_items() {
		$featured_ids = self::get_featured_playlist_ids();
		if ( empty( $featured_ids ) ) {
			return array();
		}

		$by_id = array();
		$all   = self::get_all_playlists();
		if ( ! is_wp_error( $all ) ) {
			foreach ( $all as $playlist ) {
				$by_id[ $playlist['id'] ] = $playlist;
			}
		}

		$items = array();
		foreach ( $featured_ids as $id ) {
			if ( isset( $by_id[ $id ] ) ) {
				$items[] = $by_id[ $id ];
				continue;
			}

			$items[] = array(
				'id'            => $id,
				'title'         => $id,
				'thumbnail_url' => '',
				'video_count'   => 0,
			);
		}

		return $items;
	}

	/**
	 * @param string $playlist_id Playlist ID.
	 * @param int    $per_page    Per page.
	 * @param int    $page        Page (1-based).
	 * @return array<string,mixed>|WP_Error
	 */
	public static function get_playlist_videos( $playlist_id, $per_page = 20, $page = 1 ) {
		$cache_key = 'ru_yt_plvideos_' . md5( $playlist_id . '|' . (int) $per_page . '|' . (int) $page );
		$cached    = get_transient( $cache_key );
		if ( is_array( $cached ) ) {
			return $cached;
		}

		$page_token = '';
		if ( $page > 1 ) {
			$page_token = self::get_playlist_page_token( $playlist_id, $per_page, $page );
			if ( is_wp_error( $page_token ) ) {
				return $page_token;
			}
		}

		$params = array(
			'part'       => 'snippet,contentDetails',
			'playlistId' => $playlist_id,
			'maxResults' => (int) $per_page,
		);
		if ( $page_token !== '' ) {
			$params['pageToken'] = $page_token;
		}

		$data = self::api_get( 'playlistItems', $params );
		if ( is_wp_error( $data ) ) {
			return $data;
		}

		$videos = self::map_playlist_items_to_videos( isset( $data['items'] ) ? $data['items'] : array() );
		$result = array(
			'items'       => $videos,
			'page'        => (int) $page,
			'per_page'    => (int) $per_page,
			'total'       => null,
			'total_pages' => null,
		);

		set_transient( $cache_key, $result, self::CACHE_PLAYLISTS_TTL );
		return $result;
	}

	/**
	 * @param string $query    Search query.
	 * @param int    $per_page Per page.
	 * @param int    $page     Page.
	 * @return array<string,mixed>|WP_Error
	 */
	public static function search_videos( $query, $per_page = 20, $page = 1 ) {
		$channel_id = self::resolve_channel_id();
		if ( is_wp_error( $channel_id ) ) {
			return $channel_id;
		}

		$cache_key = 'ru_yt_search_' . md5( $channel_id . '|' . strtolower( $query ) . '|' . (int) $per_page . '|' . (int) $page );
		$cached    = get_transient( $cache_key );
		if ( is_array( $cached ) ) {
			return $cached;
		}

		$page_token = '';
		if ( $page > 1 ) {
			$page_token = self::get_search_page_token( $channel_id, $query, $per_page, $page );
			if ( is_wp_error( $page_token ) ) {
				return $page_token;
			}
		}

		$params = array(
			'part'       => 'snippet',
			'channelId'  => $channel_id,
			'type'       => 'video',
			'q'          => $query,
			'maxResults' => (int) $per_page,
			'order'      => 'relevance',
		);
		if ( $page_token !== '' ) {
			$params['pageToken'] = $page_token;
		}

		$data = self::api_get( 'search', $params );
		if ( is_wp_error( $data ) ) {
			return $data;
		}

		$video_ids = array();
		foreach ( isset( $data['items'] ) ? $data['items'] : array() as $item ) {
			$id = isset( $item['id']['videoId'] ) ? (string) $item['id']['videoId'] : '';
			if ( $id !== '' ) {
				$video_ids[] = $id;
			}
		}

		$videos = self::fetch_videos_by_ids( $video_ids );
		if ( is_wp_error( $videos ) ) {
			return $videos;
		}

		$result = array(
			'items'    => $videos,
			'page'     => (int) $page,
			'per_page' => (int) $per_page,
			'query'    => $query,
		);

		set_transient( $cache_key, $result, self::CACHE_SEARCH_TTL );
		return $result;
	}

	/**
	 * @return string|WP_Error
	 */
	private static function resolve_channel_id() {
		$input = self::get_channel_input();
		if ( self::looks_like_channel_id( $input ) ) {
			return $input;
		}

		$cache_key = 'ru_yt_channel_' . md5( strtolower( $input ) );
		$cached    = get_transient( $cache_key );
		if ( is_string( $cached ) && $cached !== '' ) {
			return $cached;
		}

		$handle = ltrim( $input, '@' );
		$data   = self::api_get(
			'channels',
			array(
				'part'      => 'id,contentDetails',
				'forHandle' => $handle,
			)
		);

		if ( is_wp_error( $data ) ) {
			return $data;
		}

		if ( empty( $data['items'][0]['id'] ) ) {
			$fallback = self::api_get(
				'channels',
				array(
					'part' => 'id',
					'id'   => self::DEFAULT_CHANNEL_ID,
				)
			);
			if ( ! is_wp_error( $fallback ) && ! empty( $fallback['items'][0]['id'] ) ) {
				$channel_id = (string) $fallback['items'][0]['id'];
				set_transient( $cache_key, $channel_id, self::CACHE_PLAYLISTS_TTL );
				return $channel_id;
			}

			return new WP_Error(
				'youtube_channel_not_found',
				__( 'YouTube channel could not be resolved.', 'radioudaan-app-api' ),
				array( 'status' => 502 )
			);
		}

		$channel_id = (string) $data['items'][0]['id'];
		set_transient( $cache_key, $channel_id, self::CACHE_PLAYLISTS_TTL );
		return $channel_id;
	}

	/**
	 * @param string $channel_id Channel ID.
	 * @return string|WP_Error
	 */
	private static function get_uploads_playlist_id( $channel_id ) {
		$cache_key = 'ru_yt_uploads_' . md5( $channel_id );
		$cached    = get_transient( $cache_key );
		if ( is_string( $cached ) && $cached !== '' ) {
			return $cached;
		}

		$data = self::api_get(
			'channels',
			array(
				'part' => 'contentDetails',
				'id'   => $channel_id,
			)
		);
		if ( is_wp_error( $data ) ) {
			return $data;
		}

		$uploads = isset( $data['items'][0]['contentDetails']['relatedPlaylists']['uploads'] )
			? (string) $data['items'][0]['contentDetails']['relatedPlaylists']['uploads']
			: '';

		if ( $uploads === '' ) {
			return new WP_Error(
				'youtube_uploads_missing',
				__( 'Channel uploads playlist not found.', 'radioudaan-app-api' ),
				array( 'status' => 502 )
			);
		}

		set_transient( $cache_key, $uploads, self::CACHE_PLAYLISTS_TTL );
		return $uploads;
	}

	/**
	 * @param string $endpoint API resource (e.g. playlists).
	 * @param array<string,mixed> $params Query params.
	 * @return array<string,mixed>|WP_Error
	 */
	private static function api_get( $endpoint, array $params ) {
		$key = self::get_api_key();
		if ( $key === '' ) {
			return new WP_Error(
				'youtube_not_configured',
				__( 'YouTube API is not configured.', 'radioudaan-app-api' ),
				array( 'status' => 503 )
			);
		}

		$params['key'] = $key;
		$url           = self::API_BASE . $endpoint . '?' . http_build_query( $params, '', '&', PHP_QUERY_RFC3986 );

		$response = wp_remote_get(
			$url,
			array(
				'timeout' => 15,
			)
		);

		if ( is_wp_error( $response ) ) {
			RadioUdaan_App_Logger::log( 'youtube_http_error', array( 'endpoint' => sanitize_key( $endpoint ) ) );
			return new WP_Error(
				'youtube_request_failed',
				__( 'YouTube request failed.', 'radioudaan-app-api' ),
				array( 'status' => 502 )
			);
		}

		$code = (int) wp_remote_retrieve_response_code( $response );
		$body = json_decode( (string) wp_remote_retrieve_body( $response ), true );

		if ( $code < 200 || $code >= 300 ) {
			$message = __( 'YouTube API error.', 'radioudaan-app-api' );
			if ( is_array( $body ) && isset( $body['error']['message'] ) ) {
				$message = sanitize_text_field( (string) $body['error']['message'] );
			}
			RadioUdaan_App_Logger::log(
				'youtube_api_error',
				array(
					'endpoint' => sanitize_key( $endpoint ),
					'status'   => $code,
				)
			);
			return new WP_Error( 'youtube_api_error', $message, array( 'status' => $code >= 400 && $code < 600 ? $code : 502 ) );
		}

		return is_array( $body ) ? $body : array();
	}

	/**
	 * @param array<int,array<string,mixed>> $items Playlist items.
	 * @return array<int,array<string,mixed>>
	 */
	private static function map_playlist_items_to_videos( array $items ) {
		$video_ids = array();
		foreach ( $items as $item ) {
			$id = isset( $item['contentDetails']['videoId'] ) ? (string) $item['contentDetails']['videoId'] : '';
			if ( $id !== '' ) {
				$video_ids[] = $id;
			}
		}

		$details = self::fetch_videos_by_ids( $video_ids );
		if ( is_wp_error( $details ) ) {
			return array();
		}

		$by_id = array();
		foreach ( $details as $video ) {
			$by_id[ $video['id'] ] = $video;
		}

		$ordered = array();
		foreach ( $video_ids as $id ) {
			if ( isset( $by_id[ $id ] ) ) {
				$ordered[] = $by_id[ $id ];
			}
		}

		return $ordered;
	}

	/**
	 * @param string[] $video_ids Video IDs.
	 * @return array<int,array<string,mixed>>|WP_Error
	 */
	private static function fetch_videos_by_ids( array $video_ids ) {
		$video_ids = array_values( array_unique( array_filter( $video_ids ) ) );
		if ( empty( $video_ids ) ) {
			return array();
		}

		$videos = array();
		$chunks = array_chunk( $video_ids, 50 );
		foreach ( $chunks as $chunk ) {
			$data = self::api_get(
				'videos',
				array(
					'part' => 'snippet,contentDetails',
					'id'   => implode( ',', $chunk ),
				)
			);
			if ( is_wp_error( $data ) ) {
				return $data;
			}

			foreach ( isset( $data['items'] ) ? $data['items'] : array() as $item ) {
				$mapped = self::map_video( $item );
				if ( $mapped ) {
					$videos[] = $mapped;
				}
			}
		}

		return $videos;
	}

	/**
	 * @param array<string,mixed> $item Playlist resource.
	 * @return array<string,mixed>|null
	 */
	private static function map_playlist( array $item ) {
		$id = isset( $item['id'] ) ? (string) $item['id'] : '';
		if ( $id === '' ) {
			return null;
		}

		$snippet = isset( $item['snippet'] ) && is_array( $item['snippet'] ) ? $item['snippet'] : array();
		$thumb   = self::pick_thumbnail( isset( $snippet['thumbnails'] ) ? $snippet['thumbnails'] : array() );

		return array(
			'id'            => $id,
			'title'         => isset( $snippet['title'] ) ? sanitize_text_field( (string) $snippet['title'] ) : '',
			'description'   => isset( $snippet['description'] ) ? wp_strip_all_tags( (string) $snippet['description'] ) : '',
			'thumbnail_url' => $thumb,
			'video_count'   => isset( $item['contentDetails']['itemCount'] ) ? (int) $item['contentDetails']['itemCount'] : 0,
		);
	}

	/**
	 * @param array<string,mixed> $item Video resource.
	 * @return array<string,mixed>|null
	 */
	private static function map_video( array $item ) {
		$id = isset( $item['id'] ) ? (string) $item['id'] : '';
		if ( $id === '' ) {
			return null;
		}

		$snippet = isset( $item['snippet'] ) && is_array( $item['snippet'] ) ? $item['snippet'] : array();
		$thumb   = self::pick_thumbnail( isset( $snippet['thumbnails'] ) ? $snippet['thumbnails'] : array() );
		$iso     = isset( $item['contentDetails']['duration'] ) ? (string) $item['contentDetails']['duration'] : '';

		return array(
			'id'              => $id,
			'title'           => isset( $snippet['title'] ) ? sanitize_text_field( (string) $snippet['title'] ) : '',
			'description'     => self::summarize_description( isset( $snippet['description'] ) ? (string) $snippet['description'] : '' ),
			'thumbnail_url'   => $thumb,
			'published_at'    => isset( $snippet['publishedAt'] ) ? sanitize_text_field( (string) $snippet['publishedAt'] ) : '',
			'duration_label'  => self::format_duration_label( $iso ),
			'youtube_url'     => 'https://www.youtube.com/watch?v=' . rawurlencode( $id ),
		);
	}

	/**
	 * Returns the video-specific part of a description (strips channel footer boilerplate).
	 *
	 * @param string $description Raw YouTube description.
	 * @return string
	 */
	private static function summarize_description( $description ) {
		$text = trim( wp_strip_all_tags( (string) $description ) );
		if ( $text === '' ) {
			return '';
		}

		$markers = array(
			'Welcome to the official YouTube channel of Radio Udaan',
			'Contact Information:',
			'Stay Connected:',
			'Email us:',
			'subscribe, like, and hit the notification bell',
		);

		foreach ( $markers as $marker ) {
			$pos = stripos( $text, $marker );
			if ( $pos === 0 ) {
				return '';
			}
			if ( $pos !== false && $pos > 0 ) {
				$text = trim( substr( $text, 0, $pos ) );
			}
		}

		$parts = preg_split( '/\n\s*\n/', $text );
		$text  = trim( (string) ( $parts[0] ?? $text ) );
		if ( $text === '' ) {
			return '';
		}

		if ( mb_strlen( $text ) > 500 ) {
			$text = mb_substr( $text, 0, 497 ) . '...';
		}

		return $text;
	}

	/**
	 * @param array<string,mixed> $thumbnails Thumbnails map.
	 * @return string
	 */
	private static function pick_thumbnail( array $thumbnails ) {
		foreach ( array( 'maxres', 'standard', 'high', 'medium', 'default' ) as $size ) {
			if ( ! empty( $thumbnails[ $size ]['url'] ) ) {
				return esc_url_raw( (string) $thumbnails[ $size ]['url'] );
			}
		}
		return '';
	}

	/**
	 * ISO 8601 duration (PT#H#M#S) → human label.
	 *
	 * @param string $iso ISO duration.
	 * @return string
	 */
	private static function format_duration_label( $iso ) {
		if ( $iso === '' || ! preg_match( '/^PT/', $iso ) ) {
			return '';
		}

		$hours   = 0;
		$minutes = 0;
		$seconds = 0;

		if ( preg_match( '/(\d+)H/', $iso, $m ) ) {
			$hours = (int) $m[1];
		}
		if ( preg_match( '/(\d+)M/', $iso, $m ) ) {
			$minutes = (int) $m[1];
		}
		if ( preg_match( '/(\d+)S/', $iso, $m ) ) {
			$seconds = (int) $m[1];
		}

		if ( $hours > 0 ) {
			return sprintf( '%d:%02d:%02d', $hours, $minutes, $seconds );
		}

		return sprintf( '%d:%02d', $minutes, $seconds );
	}

	/**
	 * @param string $value Channel input.
	 * @return bool
	 */
	private static function looks_like_channel_id( $value ) {
		return (bool) preg_match( '/^UC[\w-]{22}$/', (string) $value );
	}

	/**
	 * @param string $playlist_id Playlist ID.
	 * @param int    $per_page    Per page.
	 * @param int    $page        Target page.
	 * @return string|WP_Error
	 */
	private static function get_playlist_page_token( $playlist_id, $per_page, $page ) {
		$token = '';
		for ( $i = 1; $i < $page; $i++ ) {
			$params = array(
				'part'       => 'snippet',
				'playlistId' => $playlist_id,
				'maxResults' => (int) $per_page,
			);
			if ( $token !== '' ) {
				$params['pageToken'] = $token;
			}

			$data = self::api_get( 'playlistItems', $params );
			if ( is_wp_error( $data ) ) {
				return $data;
			}

			$token = isset( $data['nextPageToken'] ) ? (string) $data['nextPageToken'] : '';
			if ( $token === '' ) {
				return new WP_Error(
					'youtube_page_out_of_range',
					__( 'Requested page is out of range.', 'radioudaan-app-api' ),
					array( 'status' => 400 )
				);
			}
		}

		return $token;
	}

	/**
	 * @param string $channel_id Channel ID.
	 * @param string $query      Query.
	 * @param int    $per_page   Per page.
	 * @param int    $page       Target page.
	 * @return string|WP_Error
	 */
	private static function get_search_page_token( $channel_id, $query, $per_page, $page ) {
		$token = '';
		for ( $i = 1; $i < $page; $i++ ) {
			$params = array(
				'part'       => 'snippet',
				'channelId'  => $channel_id,
				'type'       => 'video',
				'q'          => $query,
				'maxResults' => (int) $per_page,
			);
			if ( $token !== '' ) {
				$params['pageToken'] = $token;
			}

			$data = self::api_get( 'search', $params );
			if ( is_wp_error( $data ) ) {
				return $data;
			}

			$token = isset( $data['nextPageToken'] ) ? (string) $data['nextPageToken'] : '';
			if ( $token === '' ) {
				return new WP_Error(
					'youtube_page_out_of_range',
					__( 'Requested page is out of range.', 'radioudaan-app-api' ),
					array( 'status' => 400 )
				);
			}
		}

		return $token;
	}
}
