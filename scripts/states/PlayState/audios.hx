public function startSong()
{
    Conductor.play(Paths.inst(songRoute));
}